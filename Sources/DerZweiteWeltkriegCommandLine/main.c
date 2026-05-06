#include "der_Zweite_Weltkrieg.h"

#include <float.h>
#include <inttypes.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define CLI_BOARD_WIDTH 72.0f
#define CLI_BOARD_HEIGHT 48.0f
#define CLI_POINTS_LIMIT 750
#define CLI_MAX_AUTOPLAY_STEPS 512
#define CLI_MAX_CATALOG_ENTRIES 64
#define CLI_MAX_LIST_ITEMS 256
#define CLI_MAX_LIST_ENTRIES 64
#define CLI_MAX_UNITS 32
#define CLI_MATCH_ITERATIONS 4

typedef struct {
    uint32_t state;
} cli_rng_t;

typedef struct {
    int catalog_id;
    const char *name;
    int points;
    int max_count;
} cli_catalog_entry_t;

typedef struct {
    army_list_entry_t entries[CLI_MAX_LIST_ENTRIES];
    int entry_count;
    int total_points;
} cli_army_list_t;

typedef struct {
    int previous_node;
    int item_index;
    int unit_count;
} cli_choice_node_t;

static const army_list_t cli_allied_army_pool[] = {
    DZW_ARMY_BRITISH,
    DZW_ARMY_AMERICAN,
    DZW_ARMY_AUSTRALIAN,
    DZW_ARMY_SOVIET
};

static const army_list_t cli_axis_army_pool[] = {
    DZW_ARMY_GERMAN,
    DZW_ARMY_ITALIAN
};

static const char *player_label(player_t player) {
    switch (player) {
        case DZW_PLAYER_ONE:
            return "Player 1";
        case DZW_PLAYER_TWO:
            return "Player 2";
        default:
            return "None";
    }
}

static const char *phase_label(phase_t phase) {
    switch (phase) {
        case DZW_PHASE_MOVEMENT:
            return "Movement";
        case DZW_PHASE_SHOOTING:
            return "Shooting";
        case DZW_PHASE_ASSAULT:
            return "Assault";
        default:
            return "Unknown";
    }
}

static const char *terrain_label(terrain_kind_t kind) {
    switch (kind) {
        case DZW_TERRAIN_OPEN:
            return "Open";
        case DZW_TERRAIN_DIFFICULT:
            return "Difficult";
        case DZW_TERRAIN_IMPASSABLE:
            return "Impassable";
        default:
            return "Unknown";
    }
}

static const char *unit_kind_label(unit_kind_t kind) {
    switch (kind) {
        case DZW_UNIT_INFANTRY:
            return "Infantry";
        case DZW_UNIT_VEHICLE:
            return "Vehicle";
        case DZW_UNIT_ASSAULT_GUN:
            return "Assault Gun";
        default:
            return "Unknown";
    }
}

static const char *allegiance_label(army_list_t army) {
    switch (army) {
        case DZW_ARMY_BRITISH:
        case DZW_ARMY_AMERICAN:
        case DZW_ARMY_AUSTRALIAN:
        case DZW_ARMY_SOVIET:
            return "Allies";
        case DZW_ARMY_GERMAN:
        case DZW_ARMY_ITALIAN:
            return "Axis";
        case DZW_ARMY_DEMO:
        default:
            return "Training";
    }
}

static uint32_t cli_rng_next(cli_rng_t *rng) {
    if (rng->state == 0) {
        rng->state = 0x6D2B79F5u;
    }
    uint32_t x = rng->state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    rng->state = x;
    return x;
}

static int cli_random_bounded(cli_rng_t *rng, int upper_bound) {
    if (upper_bound <= 1) {
        return 0;
    }
    return (int)(cli_rng_next(rng) % (uint32_t)upper_bound);
}

static void cli_shuffle_ints(int *values, int count, cli_rng_t *rng) {
    for (int index = count - 1; index > 0; index -= 1) {
        int other = cli_random_bounded(rng, index + 1);
        int swap = values[index];
        values[index] = values[other];
        values[other] = swap;
    }
}

static float clampf_cli(float value, float min_value, float max_value) {
    if (value < min_value) {
        return min_value;
    }
    if (value > max_value) {
        return max_value;
    }
    return value;
}

static float edge_distance_between(const unit_view_t *lhs, const unit_view_t *rhs) {
    float dx = lhs->x - rhs->x;
    float dy = lhs->y - rhs->y;
    float center_distance = sqrtf(dx * dx + dy * dy);
    float edge_distance = center_distance - lhs->footprint_radius - rhs->footprint_radius;
    return edge_distance > 0.0f ? edge_distance : 0.0f;
}

static bool unit_uses_vehicle_rules(const unit_view_t *unit) {
    return unit->kind != DZW_UNIT_INFANTRY || unit->front_armour > 0 || unit->side_armour > 0 || unit->rear_armour > 0;
}

static float movement_allowance_for_unit(const unit_view_t *unit) {
    if (unit->kind == DZW_UNIT_VEHICLE) {
        return unit->fast ? 18.0f : 12.0f;
    }
    return 6.0f;
}

static void print_last_error_if_any(const game_t *game, const char *context) {
    const char *error = game_last_error(game);
    if (error != NULL && error[0] != '\0') {
        printf("[error] %s: %s\n", context, error);
    }
}

static unit_view_t find_unit_by_id(const game_t *game, int unit_id, bool *found) {
    unit_view_t view;
    memset(&view, 0, sizeof(view));

    int unit_count = game_unit_count(game);
    for (int index = 0; index < unit_count; index += 1) {
        view = game_unit_view(game, index);
        if (view.id == unit_id) {
            if (found != NULL) {
                *found = true;
            }
            return view;
        }
    }

    if (found != NULL) {
        *found = false;
    }
    memset(&view, 0, sizeof(view));
    return view;
}

static int count_surviving_units(const game_t *game, player_t owner) {
    int survivors = 0;
    int unit_count = game_unit_count(game);
    for (int index = 0; index < unit_count; index += 1) {
        unit_view_t unit = game_unit_view(game, index);
        if (unit.owner == owner && !unit.destroyed && !unit.embarked) {
            survivors += 1;
        }
    }
    return survivors;
}

static int total_remaining_wounds(const game_t *game, player_t owner) {
    int wounds = 0;
    int unit_count = game_unit_count(game);
    for (int index = 0; index < unit_count; index += 1) {
        unit_view_t unit = game_unit_view(game, index);
        if (unit.owner == owner && !unit.destroyed && !unit.embarked) {
            wounds += unit.total_wounds_remaining;
        }
    }
    return wounds;
}

static void print_new_logs(const game_t *game, int *last_log_index) {
    int log_count = game_log_count(game);
    for (int index = *last_log_index; index < log_count; index += 1) {
        printf("[log] %s\n", game_log_line(game, index));
    }
    *last_log_index = log_count;
}

static int load_catalog_entries(army_list_t army, cli_catalog_entry_t *catalog_entries, int max_entries) {
    int catalog_count = army_catalog_unit_count(army);
    if (catalog_count > max_entries) {
        catalog_count = max_entries;
    }

    for (int index = 0; index < catalog_count; index += 1) {
        army_catalog_unit_view_t raw = army_catalog_unit_view(army, index);
        catalog_entries[index].catalog_id = raw.catalog_id;
        catalog_entries[index].name = raw.name;
        catalog_entries[index].points = raw.points;
        catalog_entries[index].max_count = raw.max_count;
    }

    return catalog_count;
}

static const char *catalog_name_for_id(army_list_t army, int catalog_id) {
    int catalog_count = army_catalog_unit_count(army);
    for (int index = 0; index < catalog_count; index += 1) {
        army_catalog_unit_view_t raw = army_catalog_unit_view(army, index);
        if (raw.catalog_id == catalog_id) {
            return raw.name;
        }
    }
    return "Unknown Unit";
}

static cli_army_list_t build_random_army_list(army_list_t army, int target_points, cli_rng_t *rng) {
    cli_army_list_t selection;
    memset(&selection, 0, sizeof(selection));

    cli_catalog_entry_t catalog_entries[CLI_MAX_CATALOG_ENTRIES];
    int catalog_count = load_catalog_entries(army, catalog_entries, CLI_MAX_CATALOG_ENTRIES);
    if (catalog_count <= 0) {
        return selection;
    }

    int item_catalog_indices[CLI_MAX_LIST_ITEMS];
    int item_count = 0;
    int cheapest_index = -1;
    for (int index = 0; index < catalog_count; index += 1) {
        if (cheapest_index < 0 || catalog_entries[index].points < catalog_entries[cheapest_index].points) {
            cheapest_index = index;
        }
        for (int copy = 0; copy < catalog_entries[index].max_count && item_count < CLI_MAX_LIST_ITEMS; copy += 1) {
            item_catalog_indices[item_count] = index;
            item_count += 1;
        }
    }

    if (item_count <= 0) {
        if (cheapest_index >= 0) {
            selection.entries[0].catalog_id = catalog_entries[cheapest_index].catalog_id;
            selection.entries[0].count = 1;
            selection.entry_count = 1;
            selection.total_points = catalog_entries[cheapest_index].points;
        }
        return selection;
    }

    cli_shuffle_ints(item_catalog_indices, item_count, rng);

    int capped_target = target_points > 0 ? target_points : catalog_entries[cheapest_index].points;
    int *dp = (int *)malloc((size_t)(capped_target + 1) * sizeof(int));
    cli_choice_node_t *nodes = (cli_choice_node_t *)malloc((size_t)(item_count * (capped_target + 1) + 1) * sizeof(cli_choice_node_t));
    if (dp == NULL || nodes == NULL) {
        free(dp);
        free(nodes);
        if (cheapest_index >= 0) {
            selection.entries[0].catalog_id = catalog_entries[cheapest_index].catalog_id;
            selection.entries[0].count = 1;
            selection.entry_count = 1;
            selection.total_points = catalog_entries[cheapest_index].points;
        }
        return selection;
    }

    for (int total = 0; total <= capped_target; total += 1) {
        dp[total] = -1;
    }
    nodes[0].previous_node = -1;
    nodes[0].item_index = -1;
    nodes[0].unit_count = 0;
    dp[0] = 0;
    int node_count = 1;

    for (int item_index = 0; item_index < item_count; item_index += 1) {
        int catalog_index = item_catalog_indices[item_index];
        int points = catalog_entries[catalog_index].points;
        if (points > capped_target) {
            continue;
        }

        for (int total = capped_target; total >= points; total -= 1) {
            int previous_node = dp[total - points];
            if (previous_node < 0) {
                continue;
            }

            int candidate_unit_count = nodes[previous_node].unit_count + 1;
            bool replace = false;
            if (dp[total] < 0) {
                replace = true;
            } else {
                int current_unit_count = nodes[dp[total]].unit_count;
                if (candidate_unit_count > current_unit_count) {
                    replace = true;
                } else if (candidate_unit_count == current_unit_count && cli_random_bounded(rng, 2) == 0) {
                    replace = true;
                }
            }

            if (replace) {
                nodes[node_count].previous_node = previous_node;
                nodes[node_count].item_index = item_index;
                nodes[node_count].unit_count = candidate_unit_count;
                dp[total] = node_count;
                node_count += 1;
            }
        }
    }

    int best_total = capped_target;
    while (best_total > 0 && dp[best_total] < 0) {
        best_total -= 1;
    }

    if (best_total == 0 && cheapest_index >= 0) {
        selection.entries[0].catalog_id = catalog_entries[cheapest_index].catalog_id;
        selection.entries[0].count = 1;
        selection.entry_count = 1;
        selection.total_points = catalog_entries[cheapest_index].points;
        free(dp);
        free(nodes);
        return selection;
    }

    int catalog_counts[CLI_MAX_CATALOG_ENTRIES];
    memset(catalog_counts, 0, sizeof(catalog_counts));

    int node_index = dp[best_total];
    while (node_index > 0) {
        int shuffled_item_index = nodes[node_index].item_index;
        int catalog_index = item_catalog_indices[shuffled_item_index];
        catalog_counts[catalog_index] += 1;
        node_index = nodes[node_index].previous_node;
    }

    for (int index = 0; index < catalog_count && selection.entry_count < CLI_MAX_LIST_ENTRIES; index += 1) {
        if (catalog_counts[index] <= 0) {
            continue;
        }
        selection.entries[selection.entry_count].catalog_id = catalog_entries[index].catalog_id;
        selection.entries[selection.entry_count].count = catalog_counts[index];
        selection.entry_count += 1;
    }
    selection.total_points = army_list_total_points(army, selection.entries, selection.entry_count);

    free(dp);
    free(nodes);
    return selection;
}

static void build_matched_random_lists(army_list_t player_one_army, army_list_t player_two_army, int points_limit, cli_rng_t *rng, cli_army_list_t *player_one_list, cli_army_list_t *player_two_list) {
    int target_points = points_limit;
    memset(player_one_list, 0, sizeof(*player_one_list));
    memset(player_two_list, 0, sizeof(*player_two_list));

    for (int iteration = 0; iteration < CLI_MATCH_ITERATIONS; iteration += 1) {
        *player_one_list = build_random_army_list(player_one_army, target_points, rng);
        *player_two_list = build_random_army_list(player_two_army, target_points, rng);

        if (player_one_list->total_points == player_two_list->total_points) {
            return;
        }

        int next_target = player_one_list->total_points < player_two_list->total_points ? player_one_list->total_points : player_two_list->total_points;
        if (next_target <= 0 || next_target == target_points) {
            return;
        }
        target_points = next_target;
    }
}

static void choose_distinct_armies(cli_rng_t *rng, army_list_t *player_one_army, army_list_t *player_two_army) {
    int allied_count = (int)(sizeof(cli_allied_army_pool) / sizeof(cli_allied_army_pool[0]));
    int axis_count = (int)(sizeof(cli_axis_army_pool) / sizeof(cli_axis_army_pool[0]));
    *player_one_army = cli_allied_army_pool[cli_random_bounded(rng, allied_count)];
    *player_two_army = cli_axis_army_pool[cli_random_bounded(rng, axis_count)];
}

static void print_army_list(const char *label, army_list_t army, const cli_army_list_t *list) {
    printf("%s: %s %s (%d pts)\n", label, allegiance_label(army), army_name(army), list->total_points);
    for (int index = 0; index < list->entry_count; index += 1) {
        const army_list_entry_t *entry = &list->entries[index];
        const char *unit_name = catalog_name_for_id(army, entry->catalog_id);
        int points_each = 0;
        int catalog_count = army_catalog_unit_count(army);
        for (int catalog_index = 0; catalog_index < catalog_count; catalog_index += 1) {
            army_catalog_unit_view_t unit = army_catalog_unit_view(army, catalog_index);
            if (unit.catalog_id == entry->catalog_id) {
                points_each = unit.points;
                break;
            }
        }
        printf("  - %dx %s (%d pts each)\n", entry->count, unit_name, points_each);
    }
}

static void print_objectives(const game_t *game) {
    printf("Objectives:\n");
    int objective_count = game_objective_count(game);
    for (int index = 0; index < objective_count; index += 1) {
        objective_view_t objective = game_objective_view(game, index);
        printf("  - %s at (%.1f, %.1f), radius %.1f, control %s, presence P1=%d P2=%d\n",
            objective.name,
            objective.x,
            objective.y,
            objective.radius,
            player_label(objective.controller),
            objective.player_one_presence,
            objective.player_two_presence);
    }
}

static void print_zones(const game_t *game) {
    printf("Terrain Zones:\n");
    int zone_count = game_zone_count(game);
    for (int index = 0; index < zone_count; index += 1) {
        zone_view_t zone = game_zone_view(game, index);
        printf("  - %s [%s] rect=(%.1f, %.1f, %.1f, %.1f), cover %d+, blocks LOS=%s, hull-down=%s\n",
            zone.name,
            terrain_label(zone.kind),
            zone.rect.x,
            zone.rect.y,
            zone.rect.width,
            zone.rect.height,
            zone.cover_save,
            zone.blocks_line_of_sight ? "yes" : "no",
            zone.hull_down ? "yes" : "no");
    }
}

static void print_profile_groups(const game_t *game, int unit_id) {
    int group_count = game_unit_profile_group_count(game, unit_id);
    for (int index = 0; index < group_count; index += 1) {
        profile_group_view_t group = game_unit_profile_group_view(game, unit_id, index);
        if (group.name == NULL || group.models <= 0) {
            continue;
        }
        printf("      * %s: %d model(s), W%d, T%d, Sv %d+, pending hits %d%s\n",
            group.name,
            group.models,
            group.wounds_per_model,
            group.toughness,
            group.save,
            group.pending_allocated_hits,
            group.preferred_casualty_group ? ", preferred" : "");
    }
}

static void print_unit_line(const game_t *game, const unit_view_t *unit) {
    printf("  - #%d %s [%s] at (%.1f, %.1f) facing %.0f°, radius %.1f\n",
        unit->id,
        unit->name,
        unit_kind_label(unit->kind),
        unit->x,
        unit->y,
        unit->facing_degrees,
        unit->footprint_radius);

    if (unit_uses_vehicle_rules(unit)) {
        printf("      wounds=%d, armour F/S/R=%d/%d/%d, fast=%s, recon=%s, open-topped=%s\n",
            unit->total_wounds_remaining,
            unit->front_armour,
            unit->side_armour,
            unit->rear_armour,
            unit->fast ? "yes" : "no",
            unit->recon ? "yes" : "no",
            unit->open_topped ? "yes" : "no");
    } else {
        printf("      models=%d/%d, wounds remaining=%d, WS/BS=%d/%d, S/T=%d/%d, I=%d, A=%d, Ld=%d, Sv=%d+\n",
            unit->models,
            unit->starting_models,
            unit->total_wounds_remaining,
            unit->weapon_skill,
            unit->ballistic_skill,
            unit->strength,
            unit->toughness,
            unit->initiative,
            unit->attacks,
            unit->leadership,
            unit->save);
    }

    printf("      cover=%s, hull-down=%s, smoke(active/available)=%s/%s, moved=%s, shot=%s, assaulted=%s, locked=%s, pinned=%s, falling back=%s, destroyed=%s\n",
        unit->in_cover ? "yes" : "no",
        unit->hull_down ? "yes" : "no",
        unit->smoke_active ? "yes" : "no",
        unit->smoke_available ? "yes" : "no",
        unit->moved_this_turn ? "yes" : "no",
        unit->shot_this_turn ? "yes" : "no",
        unit->assaulted_this_turn ? "yes" : "no",
        unit->locked_in_assault ? "yes" : "no",
        unit->pinned ? "yes" : "no",
        unit->falling_back ? "yes" : "no",
        unit->destroyed ? "yes" : "no");

    if (unit->embarked_unit_id > 0) {
        printf("      carrying unit #%d\n", unit->embarked_unit_id);
    }
    if (unit->embarked_in_transport_id > 0) {
        printf("      embarked in transport #%d\n", unit->embarked_in_transport_id);
    }
    if (unit->mixed_profiles) {
        print_profile_groups(game, unit->id);
    }
}

static void print_units_by_player(const game_t *game, player_t owner) {
    printf("%s Units:\n", player_label(owner));
    int unit_count = game_unit_count(game);
    for (int index = 0; index < unit_count; index += 1) {
        unit_view_t unit = game_unit_view(game, index);
        if (unit.owner != owner || unit.embarked) {
            continue;
        }
        print_unit_line(game, &unit);
    }
}

static void print_battle_overview(const game_t *game, uint32_t seed, const cli_army_list_t *player_one_list, const cli_army_list_t *player_two_list) {
    game_view_t view = game_view(game);
    mission_view_t mission = game_mission_view(game);

    printf("=== derZweiteWeltkrieg World War II Battle Report ===\n");
    printf("Seed: %" PRIu32 "\n", seed);
    printf("Matchup: %s %s vs %s %s\n",
        allegiance_label(game_player_army(game, DZW_PLAYER_ONE)),
        army_name(game_player_army(game, DZW_PLAYER_ONE)),
        allegiance_label(game_player_army(game, DZW_PLAYER_TWO)),
        army_name(game_player_army(game, DZW_PLAYER_TWO)));
    printf("Mission: %s, target %d VP\n", mission.name, mission.target_score);
    printf("Initial State: Turn %d, %s to act in %s phase\n", view.turn_number, player_label(view.active_player), phase_label(view.phase));
    printf("Initial Score: Player 1 %d VP, Player 2 %d VP\n\n", mission.player_one_score, mission.player_two_score);

    print_army_list("Player 1 Army", game_player_army(game, DZW_PLAYER_ONE), player_one_list);
    print_army_list("Player 2 Army", game_player_army(game, DZW_PLAYER_TWO), player_two_list);
    printf("\n");

    print_zones(game);
    printf("\n");
    print_objectives(game);
    printf("\n");
    print_units_by_player(game, DZW_PLAYER_ONE);
    printf("\n");
    print_units_by_player(game, DZW_PLAYER_TWO);
    printf("\n");
}

static float objective_priority_for_unit(const unit_view_t *unit, player_t active_player, const objective_view_t *objective) {
    float ownership_penalty = objective->controller == active_player ? 100.0f : 0.0f;
    float dx = unit->x - objective->x;
    float dy = unit->y - objective->y;
    return ownership_penalty + sqrtf(dx * dx + dy * dy);
}

static bool choose_movement_target(const game_t *game, player_t active_player, const unit_view_t *unit, float *out_x, float *out_y) {
    float best_score = FLT_MAX;
    bool found = false;

    int objective_count = game_objective_count(game);
    for (int index = 0; index < objective_count; index += 1) {
        objective_view_t objective = game_objective_view(game, index);
        float score = objective_priority_for_unit(unit, active_player, &objective);
        if (score < best_score) {
            best_score = score;
            *out_x = objective.x;
            *out_y = objective.y;
            found = true;
        }
    }

    if (found) {
        return true;
    }

    int unit_count = game_unit_count(game);
    for (int index = 0; index < unit_count; index += 1) {
        unit_view_t target = game_unit_view(game, index);
        if (target.owner == active_player || target.destroyed || target.embarked) {
            continue;
        }
        float dx = unit->x - target.x;
        float dy = unit->y - target.y;
        float score = sqrtf(dx * dx + dy * dy);
        if (score < best_score) {
            best_score = score;
            *out_x = target.x;
            *out_y = target.y;
            found = true;
        }
    }

    return found;
}

static float target_priority_for_unit(const game_t *game, player_t active_player, const unit_view_t *unit, const unit_view_t *target) {
    float priority = edge_distance_between(unit, target);
    int objective_count = game_objective_count(game);
    for (int index = 0; index < objective_count; index += 1) {
        objective_view_t objective = game_objective_view(game, index);
        float dx = target->x - objective.x;
        float dy = target->y - objective.y;
        float distance_to_objective = sqrtf(dx * dx + dy * dy);
        if (objective.controller != active_player && distance_to_objective <= fmaxf(objective.radius + 3.0f, 6.0f)) {
            priority -= 12.0f;
            break;
        }
    }
    if (unit_uses_vehicle_rules(target)) {
        priority -= 4.0f;
    }
    return priority;
}

static bool choose_best_target(const game_t *game, player_t active_player, const unit_view_t *unit, bool require_charge_range, const int *excluded_ids, int excluded_count, unit_view_t *out_target) {
    float best_score = FLT_MAX;
    bool found = false;
    int unit_count = game_unit_count(game);

    for (int index = 0; index < unit_count; index += 1) {
        unit_view_t target = game_unit_view(game, index);
        if (target.owner == active_player || target.destroyed || target.embarked) {
            continue;
        }

        bool excluded = false;
        for (int excluded_index = 0; excluded_index < excluded_count; excluded_index += 1) {
            if (excluded_ids[excluded_index] == target.id) {
                excluded = true;
                break;
            }
        }
        if (excluded) {
            continue;
        }

        float edge_distance = edge_distance_between(unit, &target);
        if (require_charge_range && edge_distance > 8.5f) {
            continue;
        }

        float score = target_priority_for_unit(game, active_player, unit, &target);
        if (score < best_score) {
            best_score = score;
            *out_target = target;
            found = true;
        }
    }

    return found;
}

static bool resolve_pending_choices(game_t *game, int *last_log_index) {
    bool resolved_any = false;

    for (;;) {
        pending_weapon_destroy_view_t pending_weapon = game_pending_weapon_destroy_view(game);
        if (pending_weapon.active) {
            int option_count = game_pending_weapon_destroy_option_count(game);
            int chosen_weapon_index = -1;
            for (int index = 0; index < option_count; index += 1) {
                vehicle_weapon_view_t option = game_pending_weapon_destroy_option_view(game, index);
                if (option.weapon_index > chosen_weapon_index) {
                    chosen_weapon_index = option.weapon_index;
                }
            }

            if (chosen_weapon_index < 0 || !game_choose_pending_weapon_destroy(game, chosen_weapon_index)) {
                print_last_error_if_any(game, "resolving weapon-destroyed choice");
                return resolved_any;
            }

            resolved_any = true;
            print_new_logs(game, last_log_index);
            continue;
        }

        pending_hit_allocation_view_t pending_hits = game_pending_hit_allocation_view(game);
        if (pending_hits.active) {
            int group_count = game_unit_profile_group_count(game, pending_hits.target_id);
            int chosen_group_index = -1;
            int best_toughness = -1;
            int best_save = 99;

            for (int index = 0; index < group_count; index += 1) {
                profile_group_view_t group = game_unit_profile_group_view(game, pending_hits.target_id, index);
                if (group.models <= 0) {
                    continue;
                }
                if (group.toughness > best_toughness || (group.toughness == best_toughness && group.save < best_save)) {
                    chosen_group_index = group.index;
                    best_toughness = group.toughness;
                    best_save = group.save;
                }
            }

            if (chosen_group_index < 0 || !game_choose_pending_hit_allocation(game, chosen_group_index)) {
                print_last_error_if_any(game, "resolving hit-allocation choice");
                return resolved_any;
            }

            resolved_any = true;
            print_new_logs(game, last_log_index);
            continue;
        }

        return resolved_any;
    }
}

static bool rotate_toward_point(game_t *game, int unit_id, float unit_x, float unit_y, float target_x, float target_y, int *last_log_index) {
    float angle = atan2f(target_y - unit_y, target_x - unit_x) * 180.0f / (float)M_PI;
    if (!game_rotate_unit(game, unit_id, angle)) {
        return false;
    }
    print_new_logs(game, last_log_index);
    return true;
}

static bool attempt_move_toward_target(game_t *game, const unit_view_t *unit, float target_x, float target_y, int *last_log_index) {
    float dx = target_x - unit->x;
    float dy = target_y - unit->y;
    float distance = sqrtf(dx * dx + dy * dy);
    if (distance <= 0.25f) {
        return rotate_toward_point(game, unit->id, unit->x, unit->y, target_x, target_y, last_log_index);
    }

    float max_distance = movement_allowance_for_unit(unit);
    float base_angle = atan2f(dy, dx);
    const float angle_offsets[] = {0.0f, (float)M_PI / 8.0f, -(float)M_PI / 8.0f, (float)M_PI / 5.0f, -(float)M_PI / 5.0f};
    float step = fminf(distance, max_distance);

    while (step >= 1.0f) {
        for (int offset_index = 0; offset_index < (int)(sizeof(angle_offsets) / sizeof(angle_offsets[0])); offset_index += 1) {
            float angle = base_angle + angle_offsets[offset_index];
            float candidate_x = clampf_cli(unit->x + cosf(angle) * step, unit->footprint_radius, CLI_BOARD_WIDTH - unit->footprint_radius);
            float candidate_y = clampf_cli(unit->y + sinf(angle) * step, unit->footprint_radius, CLI_BOARD_HEIGHT - unit->footprint_radius);

            if (!game_move_unit(game, unit->id, candidate_x, candidate_y)) {
                continue;
            }

            print_new_logs(game, last_log_index);
            rotate_toward_point(game, unit->id, candidate_x, candidate_y, target_x, target_y, last_log_index);
            return true;
        }
        step -= 1.5f;
    }

    return rotate_toward_point(game, unit->id, unit->x, unit->y, target_x, target_y, last_log_index);
}

static bool transport_can_fire_passenger(const game_t *game, const unit_view_t *transport) {
    if (transport->transport_capacity <= 0 || transport->embarked_unit_id <= 0 || transport->destroyed) {
        return false;
    }

    game_view_t view = game_view(game);
    if (view.phase != DZW_PHASE_SHOOTING) {
        return false;
    }

    bool found = false;
    unit_view_t passenger = find_unit_by_id(game, transport->embarked_unit_id, &found);
    if (!found) {
        return false;
    }

    return !passenger.shot_this_turn && !passenger.pinned && !passenger.falling_back;
}

static void perform_movement_phase(game_t *game, int *last_log_index) {
    game_view_t view = game_view(game);
    int unit_count = game_unit_count(game);

    for (int index = 0; index < unit_count; index += 1) {
        unit_view_t unit = game_unit_view(game, index);
        if (unit.owner != view.active_player || unit.destroyed || unit.embarked || !unit.can_move_now) {
            continue;
        }

        float target_x = unit.x;
        float target_y = unit.y;
        if (choose_movement_target(game, view.active_player, &unit, &target_x, &target_y)) {
            attempt_move_toward_target(game, &unit, target_x, target_y, last_log_index);
        }
    }

    game_advance_phase(game);
    print_new_logs(game, last_log_index);
}

static void perform_shooting_phase(game_t *game, int *last_log_index) {
    game_view_t view = game_view(game);
    int unit_count = game_unit_count(game);

    for (int index = 0; index < unit_count; index += 1) {
        unit_view_t unit = game_unit_view(game, index);
        if (unit.owner != view.active_player || unit.destroyed || unit.embarked) {
            continue;
        }

        if (unit.can_shoot_now) {
            int excluded_ids[CLI_MAX_UNITS];
            int excluded_count = 0;
            unit_view_t target;
            while (choose_best_target(game, view.active_player, &unit, false, excluded_ids, excluded_count, &target) && excluded_count < CLI_MAX_UNITS) {
                if (game_shoot_unit(game, unit.id, target.id)) {
                    print_new_logs(game, last_log_index);
                    resolve_pending_choices(game, last_log_index);
                    break;
                }
                excluded_ids[excluded_count] = target.id;
                excluded_count += 1;
            }
        }

        bool found = false;
        unit_view_t updated_unit = find_unit_by_id(game, unit.id, &found);
        if (found && transport_can_fire_passenger(game, &updated_unit)) {
            int excluded_ids[CLI_MAX_UNITS];
            int excluded_count = 0;
            unit_view_t target;
            while (choose_best_target(game, view.active_player, &updated_unit, false, excluded_ids, excluded_count, &target) && excluded_count < CLI_MAX_UNITS) {
                if (game_fire_passenger(game, updated_unit.id, target.id)) {
                    print_new_logs(game, last_log_index);
                    resolve_pending_choices(game, last_log_index);
                    break;
                }
                excluded_ids[excluded_count] = target.id;
                excluded_count += 1;
            }
        }
    }

    game_advance_phase(game);
    print_new_logs(game, last_log_index);
}

static void perform_assault_phase(game_t *game, int *last_log_index) {
    game_view_t view = game_view(game);
    int unit_count = game_unit_count(game);

    for (int index = 0; index < unit_count; index += 1) {
        unit_view_t unit = game_unit_view(game, index);
        if (unit.owner != view.active_player || unit.destroyed || unit.embarked || !unit.can_assault_now) {
            continue;
        }

        int excluded_ids[CLI_MAX_UNITS];
        int excluded_count = 0;
        unit_view_t target;
        while (choose_best_target(game, view.active_player, &unit, true, excluded_ids, excluded_count, &target) && excluded_count < CLI_MAX_UNITS) {
            if (game_assault_unit(game, unit.id, target.id, DZW_FOLLOW_UP_ADVANCE)) {
                print_new_logs(game, last_log_index);
                resolve_pending_choices(game, last_log_index);
                break;
            }
            excluded_ids[excluded_count] = target.id;
            excluded_count += 1;
        }
    }

    game_advance_phase(game);
    print_new_logs(game, last_log_index);
}

static player_t determine_debug_winner(const game_t *game) {
    mission_view_t mission = game_mission_view(game);
    if (mission.winner != DZW_PLAYER_NONE) {
        return mission.winner;
    }

    if (mission.player_one_score != mission.player_two_score) {
        return mission.player_one_score > mission.player_two_score ? DZW_PLAYER_ONE : DZW_PLAYER_TWO;
    }

    int player_one_survivors = count_surviving_units(game, DZW_PLAYER_ONE);
    int player_two_survivors = count_surviving_units(game, DZW_PLAYER_TWO);
    if (player_one_survivors != player_two_survivors) {
        return player_one_survivors > player_two_survivors ? DZW_PLAYER_ONE : DZW_PLAYER_TWO;
    }

    int player_one_wounds = total_remaining_wounds(game, DZW_PLAYER_ONE);
    int player_two_wounds = total_remaining_wounds(game, DZW_PLAYER_TWO);
    if (player_one_wounds != player_two_wounds) {
        return player_one_wounds > player_two_wounds ? DZW_PLAYER_ONE : DZW_PLAYER_TWO;
    }

    return DZW_PLAYER_NONE;
}

static void print_final_summary(const game_t *game, bool reached_safety_limit) {
    game_view_t view = game_view(game);
    mission_view_t mission = game_mission_view(game);
    player_t debug_winner = determine_debug_winner(game);

    printf("\n=== Battle Result ===\n");
    if (mission.winner != DZW_PLAYER_NONE) {
        printf("Winner: %s by mission victory.\n", player_label(mission.winner));
    } else if (debug_winner != DZW_PLAYER_NONE) {
        printf("Winner: %s on debug tiebreak%s.\n",
            player_label(debug_winner),
            reached_safety_limit ? " after reaching the safety limit" : "");
    } else {
        printf("Result: draw%s.\n", reached_safety_limit ? " after reaching the safety limit" : "");
    }

    printf("Final State: Turn %d, %s in %s phase\n", view.turn_number, player_label(view.active_player), phase_label(view.phase));
    printf("Final Score: Player 1 %d VP, Player 2 %d VP\n", mission.player_one_score, mission.player_two_score);
    printf("Remaining Forces: Player 1 has %d unit(s) and %d wound(s); Player 2 has %d unit(s) and %d wound(s)\n",
        count_surviving_units(game, DZW_PLAYER_ONE),
        total_remaining_wounds(game, DZW_PLAYER_ONE),
        count_surviving_units(game, DZW_PLAYER_TWO),
        total_remaining_wounds(game, DZW_PLAYER_TWO));
    printf("\n");
    print_objectives(game);
    printf("\n");
    print_units_by_player(game, DZW_PLAYER_ONE);
    printf("\n");
    print_units_by_player(game, DZW_PLAYER_TWO);
}

static bool autoplay_battle(game_t *game, int *last_log_index) {
    for (int step = 0; step < CLI_MAX_AUTOPLAY_STEPS; step += 1) {
        mission_view_t mission = game_mission_view(game);
        if (mission.winner != DZW_PLAYER_NONE) {
            return true;
        }

        resolve_pending_choices(game, last_log_index);
        mission = game_mission_view(game);
        if (mission.winner != DZW_PLAYER_NONE) {
            return true;
        }

        game_view_t view = game_view(game);
        switch (view.phase) {
            case DZW_PHASE_MOVEMENT:
                perform_movement_phase(game, last_log_index);
                break;
            case DZW_PHASE_SHOOTING:
                perform_shooting_phase(game, last_log_index);
                break;
            case DZW_PHASE_ASSAULT:
                perform_assault_phase(game, last_log_index);
                break;
            default:
                game_advance_phase(game);
                print_new_logs(game, last_log_index);
                break;
        }
    }

    return false;
}

__attribute__((no_instrument_function))
int main(int argc, const char *argv[]) {
    uint32_t seed = (uint32_t)time(NULL);
    if (argc >= 2) {
        seed = (uint32_t)strtoul(argv[1], NULL, 10);
    }
    if (seed == 0) {
        seed = 1944u;
    }

    cli_rng_t rng = {.state = seed ^ 0x9E3779B9u};
    army_list_t player_one_army;
    army_list_t player_two_army;
    choose_distinct_armies(&rng, &player_one_army, &player_two_army);

    cli_army_list_t player_one_list;
    cli_army_list_t player_two_list;
    build_matched_random_lists(player_one_army, player_two_army, CLI_POINTS_LIMIT, &rng, &player_one_list, &player_two_list);

    game_t *game = game_create_skirmish(
        seed,
        player_one_army,
        player_one_list.entries,
        player_one_list.entry_count,
        player_two_army,
        player_two_list.entries,
        player_two_list.entry_count
    );
    if (game == NULL) {
        fprintf(stderr, "Failed to create command-line battle.\n");
        return 1;
    }

    int last_log_index = 0;
    print_battle_overview(game, seed, &player_one_list, &player_two_list);
    print_new_logs(game, &last_log_index);

    bool completed = autoplay_battle(game, &last_log_index);
    print_final_summary(game, !completed);
    mission_view_t mission = game_mission_view(game);
    player_t final_winner = mission.winner != DZW_PLAYER_NONE ? mission.winner : determine_debug_winner(game);
    const char *final_winner_label = final_winner == DZW_PLAYER_NONE ? "Draw" : player_label(final_winner);
    const char *final_outcome = mission.winner != DZW_PLAYER_NONE ? "mission victory" : (final_winner == DZW_PLAYER_NONE ? "no winner" : "debug tiebreak");

    game_destroy(game);
    printf("FINAL WINNER: %s (%s)\n", final_winner_label, final_outcome);
    fflush(stdout);
    return 0;
}
