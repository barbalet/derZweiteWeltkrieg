#include "der_Zweite_Weltkrieg.h"
#include "shared.h"

#if defined(COMMAND_LINE_EXECUTION) && defined(DZWK_ENABLE_TRACE)
#include <dlfcn.h>
#endif
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define TE_BOARD_WIDTH 72.0f
#define TE_BOARD_HEIGHT 48.0f
#define TE_MAX_UNITS 20
#define TE_MAX_ZONES 8
#define TE_MAX_OBJECTIVES 8
#define TE_MAX_WEAPONS 3
#define TE_MAX_PROFILE_GROUPS 3
#define TE_MAX_LOG_LINES 256
#define TE_LOG_LINE_LENGTH 192
#define TE_JAMMED_WEAPON_ARC_DEGREES 10
#define TE_MAX_DEPLOYMENT_SLOTS_PER_SIDE 10
#define TE_MAX_ARMY_CATALOG_UNITS 16
#ifdef HEINZ_GUDERIAN_GAME
#define TE_GUDERIAN_LABEL_LENGTH 80
#endif

#if defined(COMMAND_LINE_EXECUTION) && defined(DZWK_ENABLE_TRACE)
static __thread unsigned int te_trace_depth = 0;

__attribute__((no_instrument_function))
static const char *trace_symbol_name(void *address) {
    Dl_info info;
    if (dladdr(address, &info) != 0 && info.dli_sname != NULL) {
        return info.dli_sname;
    }
    return "(unknown)";
}

__attribute__((no_instrument_function))
static void trace_function_call(const char *direction, unsigned int depth, void *this_fn, void *call_site) {
    printf("[trace] %*s%s %s (%p <- %p)\n",
        (int)(depth * 2),
        "",
        direction,
        trace_symbol_name(this_fn),
        this_fn,
        call_site);
    fflush(stdout);
}

__attribute__((no_instrument_function))
void __cyg_profile_func_enter(void *this_fn, void *call_site) {
    trace_function_call("->", te_trace_depth, this_fn, call_site);
    te_trace_depth += 1;
}

__attribute__((no_instrument_function))
void __cyg_profile_func_exit(void *this_fn, void *call_site) {
    if (te_trace_depth > 0) {
        te_trace_depth -= 1;
    }
    trace_function_call("<-", te_trace_depth, this_fn, call_site);
}
#endif

float game_board_width(void) {
    return TE_BOARD_WIDTH;
}

float game_board_height(void) {
    return TE_BOARD_HEIGHT;
}

typedef enum {
    TE_WEAPON_RAPID_FIRE_INTERNAL = 0,
    TE_WEAPON_ASSAULT_INTERNAL = 1,
    TE_WEAPON_HEAVY_INTERNAL = 2,
    TE_WEAPON_PISTOL_INTERNAL = 3
} weapon_mode_internal_t;

typedef enum {
    TE_WEAPON_MOUNT_FIXED_INTERNAL = 0,
    TE_WEAPON_MOUNT_TURRET_INTERNAL = 1,
    TE_WEAPON_MOUNT_SPONSON_INTERNAL = 2,
    TE_WEAPON_MOUNT_PINTLE_INTERNAL = 3
} weapon_mount_internal_t;

typedef enum {
    TE_PENDING_HIT_ALLOCATION_SHOOTING = 0,
    TE_PENDING_HIT_ALLOCATION_MELEE = 1
} pending_hit_allocation_kind_t;

typedef enum {
    TE_PENDING_ONE_SIDED_MELEE_NONE = 0,
    TE_PENDING_ONE_SIDED_MELEE_COVER_ATTACKER_STRIKE = 1,
    TE_PENDING_ONE_SIDED_MELEE_FINALIZE_ASSAULT = 2
} pending_one_sided_melee_step_t;

typedef enum {
    TE_PENDING_SIMULTANEOUS_MELEE_NONE = 0,
    TE_PENDING_SIMULTANEOUS_MELEE_RESOLVE_COUNTER = 1,
    TE_PENDING_SIMULTANEOUS_MELEE_CONTINUE_BANDS = 2
} pending_simultaneous_melee_step_t;

typedef struct {
    const char *name;
    int range;
    int strength;
    int ap;
    int shots;
    weapon_mode_internal_t mode;
    weapon_mount_internal_t mount;
    int fire_arc_degrees;
    int blast_diameter;
    bool flame;
    bool ignores_cover;
    bool ordnance;
    bool barrage;
    bool linked;
} weapon_profile_t;

typedef struct {
    weapon_profile_t profile;
    bool destroyed;
    bool jammed_in_place;
    bool has_last_fire_angle;
    float last_fire_angle_degrees;
    float jammed_fire_angle_degrees;
} weapon_slot_t;

typedef struct {
    int id;
    const char *name;
    terrain_kind_t kind;
    rect_t rect;
    int cover_save;
    bool blocks_line_of_sight;
    bool hull_down;
} zone_t;

typedef struct {
    int id;
    const char *name;
    float x;
    float y;
    float radius;
} objective_t;

typedef struct {
    const char *name;
    int models;
    int starting_models;
    int weapon_skill;
    int ballistic_skill;
    int strength;
    int toughness;
    int initiative;
    int attacks;
    int leadership;
    int save;
    int wounds_per_model;
    int lead_model_wounds;
} profile_group_t;

typedef struct {
    float x;
    float y;
    float facing_degrees;
} deployment_slot_t;

typedef struct {
    int id;
    const char *name;
    player_t owner;
    unit_kind_t kind;
    float x;
    float y;
    float facing_degrees;
    float footprint_radius;
    int starting_models;
    int models;
    int wounds_per_model;
    int lead_model_wounds;
    int weapon_skill;
    int ballistic_skill;
    int strength;
    int toughness;
    int initiative;
    int attacks;
    int leadership;
    int save;
    int front_armour;
    int side_armour;
    int rear_armour;
    bool fast;
    bool recon;
    bool open_topped;
    bool smoke_available;
    bool smoke_active;
    bool smoke_used_this_turn;
    bool moved_this_turn;
    bool movement_action_used_this_turn;
    bool shot_this_turn;
    bool assaulted_this_turn;
    float moved_distance;
    int weapon_count;
    weapon_slot_t weapons[TE_MAX_WEAPONS];
    bool locked_in_assault;
    int locked_with;
    int pinned_until_turn;
    bool falling_back;
    bool destroyed;
    bool manual_in_cover;
    bool manual_hull_down;
    int shooting_phase_strength;
    int casualties_this_shooting_phase;
    bool morale_checked_this_phase;
    bool fired_stationary_rapid_or_heavy;
    bool crew_shaken;
    bool crew_stunned;
    int crew_shaken_until_turn;
    int crew_stunned_until_turn;
    bool immobilized;
    int transport_capacity;
    int embarked_unit_id;
    int embarked_in_transport_id;
    bool embarked_this_turn;
    int profile_group_count;
    int preferred_casualty_group_index;
    profile_group_t profile_groups[TE_MAX_PROFILE_GROUPS];
} unit_t;

struct te_game {
    uint32_t rng_state;
    int turn_number;
    player_t active_player;
    phase_t phase;
    army_list_t player_one_army;
    int player_one_force;
    army_list_t player_two_army;
    int player_two_force;
    int unit_count;
    unit_t units[TE_MAX_UNITS];
    int zone_count;
    zone_t zones[TE_MAX_ZONES];
    const char *mission_name;
    int mission_target_score;
    int player_one_score;
    int player_two_score;
    int objective_count;
    objective_t objectives[TE_MAX_OBJECTIVES];
#ifdef HEINZ_GUDERIAN_GAME
    char guderian_mission_name[TE_GUDERIAN_LABEL_LENGTH];
    char guderian_zone_names[TE_MAX_ZONES][TE_GUDERIAN_LABEL_LENGTH];
    char guderian_objective_names[TE_MAX_OBJECTIVES][TE_GUDERIAN_LABEL_LENGTH];
#endif
    bool pending_weapon_destroy_active;
    int pending_weapon_destroy_chooser_id;
    int pending_weapon_destroy_target_id;
    int pending_weapon_destroy_option_count;
    int pending_weapon_destroy_option_indices[TE_MAX_WEAPONS];
    bool pending_hit_allocation_active;
    pending_hit_allocation_kind_t pending_hit_allocation_kind;
    player_t pending_hit_allocation_chooser_owner;
    const char *pending_hit_allocation_attacker_name;
    const char *pending_hit_allocation_source_name;
    int pending_hit_allocation_target_id;
    bool pending_hit_allocation_barrage;
    bool pending_hit_allocation_ordnance;
    int pending_hit_allocation_strength;
    bool pending_hit_allocation_ignores_cover;
    int pending_hit_allocation_target_models_before;
    int pending_hit_allocation_hits_remaining;
    int pending_hit_allocation_total_hits;
    int pending_hit_allocation_allocated_hits[TE_MAX_PROFILE_GROUPS];
    bool pending_banded_melee_active;
    int pending_banded_melee_attacker_id;
    int pending_banded_melee_target_id;
    follow_up_t pending_banded_melee_follow_up;
    bool pending_banded_melee_charging;
    int pending_banded_melee_next_initiative;
    int pending_banded_melee_attacker_wounds;
    int pending_banded_melee_defender_wounds;
    bool pending_banded_melee_pending_attacker_side;
    int pending_banded_melee_resolved_initiative;
    bool pending_one_sided_melee_active;
    int pending_one_sided_melee_acting_id;
    int pending_one_sided_melee_defending_id;
    bool pending_one_sided_melee_charging;
    int pending_one_sided_melee_next_initiative;
    int pending_one_sided_melee_accumulated_wounds;
    bool pending_one_sided_melee_counts_for_attacker_score;
    int pending_one_sided_melee_resolved_initiative;
    pending_one_sided_melee_step_t pending_one_sided_melee_next_step;
    int pending_one_sided_melee_assault_attacker_id;
    int pending_one_sided_melee_assault_target_id;
    follow_up_t pending_one_sided_melee_follow_up;
    int pending_one_sided_melee_attacker_wounds;
    int pending_one_sided_melee_defender_wounds;
    bool pending_simultaneous_melee_active;
    int pending_simultaneous_melee_attacker_id;
    int pending_simultaneous_melee_target_id;
    follow_up_t pending_simultaneous_melee_follow_up;
    bool pending_simultaneous_melee_charging;
    int pending_simultaneous_melee_resolved_initiative;
    int pending_simultaneous_melee_next_initiative;
    int pending_simultaneous_melee_attacker_wounds;
    int pending_simultaneous_melee_defender_wounds;
    int pending_simultaneous_melee_band_attacker_wounds;
    int pending_simultaneous_melee_band_defender_wounds;
    bool pending_simultaneous_melee_pending_counts_for_attacker_score;
    pending_simultaneous_melee_step_t pending_simultaneous_melee_step;
    bool pending_simultaneous_melee_counter_source_valid;
    unit_t pending_simultaneous_melee_counter_source;
    bool pending_vehicle_shot_active;
    int pending_vehicle_shot_attacker_id;
    int pending_vehicle_shot_target_id;
    int pending_vehicle_shot_next_weapon_index;
    int pending_vehicle_shot_weapons_remaining;
    int log_count;
    char logs[TE_MAX_LOG_LINES][TE_LOG_LINE_LENGTH];
    char last_error[TE_LOG_LINE_LENGTH];
};

static int apply_infantry_damage(game_t *game, unit_t *unit, int wounds, int damage_strength, const char *source_name, bool count_for_shooting_phase, int *out_models_lost);
static void destroy_unit(game_t *game, unit_t *unit, const char *reason);
static void destroy_unit_with_passenger_outcome(game_t *game, unit_t *unit, const char *reason, bool annihilate_embarked_units);
static bool find_disembark_position(const game_t *game, const unit_t *transport, const unit_t *unit, float *out_x, float *out_y);
static bool unit_uses_vehicle_rules(const unit_t *unit);
static int cover_save_for_unit(const game_t *game, const unit_t *unit);
static player_t mission_winner(const game_t *game);
static const char *player_name(player_t player);
static void log_profile_group_allocation(game_t *game, const unit_t *target, const int *allocated_hits);
static bool can_place_unit_at(const game_t *game, const unit_t *unit, float x, float y, int ignore_unit_id);
static float move_toward_point_legally(const game_t *game, unit_t *unit, float target_x, float target_y, float distance, int ignore_unit_id);

static weapon_profile_t with_fire_arc(weapon_profile_t weapon, int fire_arc_degrees) {
    weapon.fire_arc_degrees = fire_arc_degrees;
    return weapon;
}

static weapon_profile_t with_mount(weapon_profile_t weapon, weapon_mount_internal_t mount) {
    weapon.mount = mount;
    return weapon;
}

typedef enum {
    DZWK_WEAPON_LEE_ENFIELD_NO4 = 0,
    DZWK_WEAPON_M1911A1_PISTOL,
    DZWK_WEAPON_BROWNING_M1919A4,
    DZWK_WEAPON_17_POUNDER_AT_GUN,
    DZWK_WEAPON_75MM_TANK_GUN,
    DZWK_WEAPON_81MM_MORTAR_BATTERY,
    DZWK_WEAPON_FLAMETHROWER,
    DZWK_WEAPON_BREN_LMG,
    DZWK_WEAPON_PPSH_41_SMG,
    DZWK_WEAPON_TOKAREV_TT33,
    DZWK_WEAPON_CARCANO_M91,
    DZWK_WEAPON_BREDA_M1930,
    DZWK_WEAPON_MOSIN_NAGANT_1891_30,
    DZWK_WEAPON_NAGANT_M1895,
    DZWK_WEAPON_M1_BAZOOKA,
    DZWK_WEAPON_M2_BROWNING_HMG,
    DZWK_WEAPON_HULL_BROWNING_M1919A4,
    DZWK_WEAPON_MG42,
    DZWK_WEAPON_TWIN_MG42,
    DZWK_WEAPON_PANZERFAUST,
    DZWK_WEAPON_M3_GREASE_GUN,
    DZWK_WEAPON_120MM_MORTAR,
    DZWK_WEAPON_BERETTA_M38,
    DZWK_WEAPON_20MM_AUTOCANNON,
    DZWK_WEAPON_PIAT,
    DZWK_WEAPON_THOMPSON_SMG,
    DZWK_WEAPON_KAR98K,
    DZWK_WEAPON_MP40,
    DZWK_WEAPON_DP27_LMG,
    DZWK_WEAPON_M1_GARAND,
    DZWK_WEAPON_VICKERS_HMG,
    DZWK_WEAPON_WEBLEY_REVOLVER,
    DZWK_WEAPON_COUNT
} wwii_weapon_id_t;

/*
 * Weapon taxonomy table for World War II equipment drawn from the roadmap's
 * Wikipedia source anchors.
 */
static const weapon_profile_t wwii_weapon_profiles[DZWK_WEAPON_COUNT] = {
    [DZWK_WEAPON_LEE_ENFIELD_NO4] = {
        .name = "Lee-Enfield No.4 Mk I",
        .range = 24,
        .strength = 4,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_RAPID_FIRE_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_M1911A1_PISTOL] = {
        .name = "M1911A1 Pistol",
        .range = 12,
        .strength = 4,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_PISTOL_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_BROWNING_M1919A4] = {
        .name = "Browning M1919A4",
        .range = 36,
        .strength = 5,
        .ap = 4,
        .shots = 3,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_17_POUNDER_AT_GUN] = {
        .name = "17-pounder Anti-Tank Gun",
        .range = 48,
        .strength = 9,
        .ap = 2,
        .shots = 1,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_75MM_TANK_GUN] = {
        .name = "75mm Tank Gun",
        .range = 72,
        .strength = 8,
        .ap = 3,
        .shots = 1,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
        .blast_diameter = 5,
        .ordnance = true,
    },
    [DZWK_WEAPON_81MM_MORTAR_BATTERY] = {
        .name = "81mm Mortar Battery",
        .range = 48,
        .strength = 5,
        .ap = 4,
        .shots = 1,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
        .blast_diameter = 5,
        .ordnance = true,
        .barrage = true,
    },
    [DZWK_WEAPON_FLAMETHROWER] = {
        .name = "Flamethrower",
        .range = 8,
        .strength = 4,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_ASSAULT_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
        .flame = true,
        .ignores_cover = true,
    },
    [DZWK_WEAPON_BREN_LMG] = {
        .name = "Bren LMG",
        .range = 24,
        .strength = 4,
        .ap = 5,
        .shots = 2,
        .mode = TE_WEAPON_RAPID_FIRE_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_PPSH_41_SMG] = {
        .name = "PPSh-41 SMG",
        .range = 18,
        .strength = 5,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_ASSAULT_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_TOKAREV_TT33] = {
        .name = "Tokarev TT-33",
        .range = 12,
        .strength = 3,
        .ap = 6,
        .shots = 1,
        .mode = TE_WEAPON_PISTOL_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_CARCANO_M91] = {
        .name = "Carcano M91 Rifle",
        .range = 24,
        .strength = 3,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_RAPID_FIRE_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_BREDA_M1930] = {
        .name = "Breda M1930 LMG",
        .range = 36,
        .strength = 5,
        .ap = 5,
        .shots = 3,
        .mode = TE_WEAPON_ASSAULT_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_MOSIN_NAGANT_1891_30] = {
        .name = "Mosin-Nagant M91/30",
        .range = 24,
        .strength = 3,
        .ap = 0,
        .shots = 1,
        .mode = TE_WEAPON_RAPID_FIRE_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_NAGANT_M1895] = {
        .name = "Nagant M1895 Revolver",
        .range = 12,
        .strength = 3,
        .ap = 0,
        .shots = 1,
        .mode = TE_WEAPON_PISTOL_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_M1_BAZOOKA] = {
        .name = "M1 Bazooka",
        .range = 24,
        .strength = 7,
        .ap = 2,
        .shots = 1,
        .mode = TE_WEAPON_RAPID_FIRE_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_M2_BROWNING_HMG] = {
        .name = "M2 Browning HMG",
        .range = 36,
        .strength = 6,
        .ap = 6,
        .shots = 3,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_HULL_BROWNING_M1919A4] = {
        .name = "Hull Browning M1919A4",
        .range = 36,
        .strength = 5,
        .ap = 4,
        .shots = 3,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_MG42] = {
        .name = "MG42",
        .range = 36,
        .strength = 5,
        .ap = 4,
        .shots = 3,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_TWIN_MG42] = {
        .name = "Twin MG42",
        .range = 36,
        .strength = 5,
        .ap = 4,
        .shots = 3,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_PANZERFAUST] = {
        .name = "Panzerfaust",
        .range = 12,
        .strength = 4,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_ASSAULT_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_M3_GREASE_GUN] = {
        .name = "M3 Grease Gun",
        .range = 12,
        .strength = 3,
        .ap = 0,
        .shots = 1,
        .mode = TE_WEAPON_PISTOL_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_120MM_MORTAR] = {
        .name = "120mm Mortar",
        .range = 36,
        .strength = 8,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
        .blast_diameter = 3,
    },
    [DZWK_WEAPON_BERETTA_M38] = {
        .name = "Beretta M38 SMG",
        .range = 12,
        .strength = 4,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_ASSAULT_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_20MM_AUTOCANNON] = {
        .name = "20mm Autocannon",
        .range = 24,
        .strength = 6,
        .ap = 4,
        .shots = 4,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_PIAT] = {
        .name = "PIAT",
        .range = 24,
        .strength = 7,
        .ap = 2,
        .shots = 1,
        .mode = TE_WEAPON_RAPID_FIRE_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_THOMPSON_SMG] = {
        .name = "Thompson SMG",
        .range = 12,
        .strength = 4,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_ASSAULT_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_KAR98K] = {
        .name = "Karabiner 98k",
        .range = 24,
        .strength = 4,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_RAPID_FIRE_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_MP40] = {
        .name = "MP 40 SMG",
        .range = 12,
        .strength = 4,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_ASSAULT_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_DP27_LMG] = {
        .name = "DP-27 LMG",
        .range = 36,
        .strength = 5,
        .ap = 5,
        .shots = 3,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_M1_GARAND] = {
        .name = "M1 Garand",
        .range = 24,
        .strength = 4,
        .ap = 5,
        .shots = 1,
        .mode = TE_WEAPON_RAPID_FIRE_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_VICKERS_HMG] = {
        .name = "Vickers HMG",
        .range = 36,
        .strength = 5,
        .ap = 4,
        .shots = 3,
        .mode = TE_WEAPON_HEAVY_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
    [DZWK_WEAPON_WEBLEY_REVOLVER] = {
        .name = "Webley Revolver",
        .range = 12,
        .strength = 3,
        .ap = 6,
        .shots = 1,
        .mode = TE_WEAPON_PISTOL_INTERNAL,
        .mount = TE_WEAPON_MOUNT_FIXED_INTERNAL,
        .fire_arc_degrees = 360,
    },
};

static weapon_profile_t wwii_weapon_profile(wwii_weapon_id_t weapon_id) {
    if (weapon_id < 0 || weapon_id >= DZWK_WEAPON_COUNT) {
        return wwii_weapon_profiles[DZWK_WEAPON_LEE_ENFIELD_NO4];
    }
    return wwii_weapon_profiles[weapon_id];
}

int wwii_weapon_profile_count(void) {
    return DZWK_WEAPON_COUNT;
}

weapon_profile_view_t wwii_weapon_profile_view(int index) {
    weapon_profile_view_t view;
    memset(&view, 0, sizeof(view));

    if (index < 0 || index >= DZWK_WEAPON_COUNT) {
        return view;
    }

    weapon_profile_t profile = wwii_weapon_profiles[index];
    view.name = profile.name;
    view.range = profile.range;
    view.strength = profile.strength;
    view.ap = profile.ap;
    view.shots = profile.shots;
    view.flame = profile.flame;
    view.ignores_cover = profile.ignores_cover;
    view.ordnance = profile.ordnance;
    view.barrage = profile.barrage;
    view.blast_diameter = profile.blast_diameter;

    switch (profile.mode) {
        case TE_WEAPON_RAPID_FIRE_INTERNAL:
            view.rapid_fire = true;
            break;
        case TE_WEAPON_PISTOL_INTERNAL:
            view.pistol = true;
            break;
        case TE_WEAPON_ASSAULT_INTERNAL:
            view.assault = true;
            break;
        case TE_WEAPON_HEAVY_INTERNAL:
            view.heavy = true;
            break;
    }

    return view;
}

static void clear_error(game_t *game) {
    if (game != NULL) {
        game->last_error[0] = '\0';
    }
}

static bool fail(game_t *game, const char *format, ...) {
    if (game != NULL) {
        va_list args;
        va_start(args, format);
        vsnprintf(game->last_error, sizeof(game->last_error), format, args);
        va_end(args);
    }
    return false;
}

static void te_log(game_t *game, const char *format, ...) {
    if (game == NULL) {
        return;
    }

    if (game->log_count >= TE_MAX_LOG_LINES) {
        memmove(game->logs, game->logs + 1, sizeof(game->logs[0]) * (TE_MAX_LOG_LINES - 1));
        game->log_count = TE_MAX_LOG_LINES - 1;
    }

    va_list args;
    va_start(args, format);
    vsnprintf(game->logs[game->log_count], TE_LOG_LINE_LENGTH, format, args);
    va_end(args);
    game->log_count += 1;
}

uint32_t shared_adapter_next_random(shared_rng_t *rng) {
    game_t *game = (game_t *)rng;
    if (game->rng_state == 0) {
        game->rng_state = 0xA341316Cu;
    }

    uint32_t x = game->rng_state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    game->rng_state = x;
    return x;
}

static uint32_t next_random(game_t *game) {
    return shared_adapter_next_random((shared_rng_t *)game);
}

static int roll_d6(game_t *game) {
    return shared_roll_d6((shared_rng_t *)game);
}

static int roll_2d6(game_t *game) {
    return shared_roll_2d6((shared_rng_t *)game);
}

static int roll_highest_of_2d6(game_t *game) {
    return shared_roll_highest_of_2d6((shared_rng_t *)game);
}

static float te_distance(float x1, float y1, float x2, float y2) {
    return shared_point_distance(
        shared_make_point(x1, y1),
        shared_make_point(x2, y2)
    );
}

static shared_point_t te_shared_point(float x, float y) {
    return shared_make_point(x, y);
}

static shared_rect_t te_shared_rect(rect_t rect) {
    return shared_make_rect(rect.x, rect.y, rect.width, rect.height);
}

static float normalize_angle(float angle) {
    return shared_normalize_angle(angle);
}

static float roll_random_direction_degrees(game_t *game) {
    return normalize_angle((float)(shared_adapter_next_random((shared_rng_t *)game) % 360u));
}

static float angle_to(float x1, float y1, float x2, float y2) {
    return shared_angle_to(
        shared_make_point(x1, y1),
        shared_make_point(x2, y2)
    );
}

static float smallest_angle_between(float left, float right) {
    return shared_smallest_angle_between(left, right);
}

static bool point_in_rect(float x, float y, rect_t rect) {
    return shared_point_in_rect(te_shared_point(x, y), te_shared_rect(rect));
}

static bool segment_intersects_circle(float x1, float y1, float x2, float y2, float center_x, float center_y, float radius) {
    float dx = x2 - x1;
    float dy = y2 - y1;
    float length_squared = dx * dx + dy * dy;
    if (length_squared < 0.0001f) {
        return te_distance(x1, y1, center_x, center_y) <= radius;
    }

    float projection = ((center_x - x1) * dx + (center_y - y1) * dy) / length_squared;
    if (projection < 0.0f) {
        projection = 0.0f;
    } else if (projection > 1.0f) {
        projection = 1.0f;
    }

    float closest_x = x1 + projection * dx;
    float closest_y = y1 + projection * dy;
    return te_distance(closest_x, closest_y, center_x, center_y) <= radius + 0.001f;
}

static bool segment_intersects_rect(float x1, float y1, float x2, float y2, rect_t rect) {
    return shared_segment_intersects_rect(
        te_shared_point(x1, y1),
        te_shared_point(x2, y2),
        te_shared_rect(rect)
    );
}

static unit_t *find_unit(game_t *game, int unit_id) {
    if (game == NULL) {
        return NULL;
    }

    for (int index = 0; index < game->unit_count; index += 1) {
        if (game->units[index].id == unit_id) {
            return &game->units[index];
        }
    }
    return NULL;
}

static const unit_t *find_unit_const(const game_t *game, int unit_id) {
    if (game == NULL) {
        return NULL;
    }

    for (int index = 0; index < game->unit_count; index += 1) {
        if (game->units[index].id == unit_id) {
            return &game->units[index];
        }
    }
    return NULL;
}

static unit_t *find_unit_by_owner_and_name(game_t *game, player_t owner, const char *name) {
    if (game == NULL || name == NULL) {
        return NULL;
    }

    for (int index = 0; index < game->unit_count; index += 1) {
        unit_t *unit = &game->units[index];
        if (unit->owner == owner && strcmp(unit->name, name) == 0) {
            return unit;
        }
    }
    return NULL;
}

static bool game_has_pending_weapon_destroy_choice(const game_t *game) {
    return game != NULL && game->pending_weapon_destroy_active;
}

static bool game_has_pending_hit_allocation_choice(const game_t *game) {
    return game != NULL && game->pending_hit_allocation_active;
}

static bool game_has_pending_vehicle_shot_sequence(const game_t *game) {
    return game != NULL && game->pending_vehicle_shot_active;
}

static bool game_has_pending_banded_melee_resolution(const game_t *game) {
    return game != NULL && game->pending_banded_melee_active;
}

static bool game_has_pending_one_sided_melee_resolution(const game_t *game) {
    return game != NULL && game->pending_one_sided_melee_active;
}

static bool game_has_pending_simultaneous_melee_resolution(const game_t *game) {
    return game != NULL && game->pending_simultaneous_melee_active;
}

static void clear_pending_weapon_destroy_choice(game_t *game) {
    if (game == NULL) {
        return;
    }

    game->pending_weapon_destroy_active = false;
    game->pending_weapon_destroy_chooser_id = 0;
    game->pending_weapon_destroy_target_id = 0;
    game->pending_weapon_destroy_option_count = 0;
    memset(game->pending_weapon_destroy_option_indices, 0, sizeof(game->pending_weapon_destroy_option_indices));
}

static void clear_pending_hit_allocation_choice(game_t *game) {
    if (game == NULL) {
        return;
    }

    game->pending_hit_allocation_active = false;
    game->pending_hit_allocation_kind = TE_PENDING_HIT_ALLOCATION_SHOOTING;
    game->pending_hit_allocation_chooser_owner = TE_PLAYER_NONE;
    game->pending_hit_allocation_attacker_name = NULL;
    game->pending_hit_allocation_source_name = NULL;
    game->pending_hit_allocation_target_id = 0;
    game->pending_hit_allocation_barrage = false;
    game->pending_hit_allocation_ordnance = false;
    game->pending_hit_allocation_strength = 0;
    game->pending_hit_allocation_ignores_cover = false;
    game->pending_hit_allocation_target_models_before = 0;
    game->pending_hit_allocation_hits_remaining = 0;
    game->pending_hit_allocation_total_hits = 0;
    memset(game->pending_hit_allocation_allocated_hits, 0, sizeof(game->pending_hit_allocation_allocated_hits));
}

static void clear_pending_banded_melee_resolution(game_t *game) {
    if (game == NULL) {
        return;
    }

    game->pending_banded_melee_active = false;
    game->pending_banded_melee_attacker_id = 0;
    game->pending_banded_melee_target_id = 0;
    game->pending_banded_melee_follow_up = TE_FOLLOW_UP_ADVANCE;
    game->pending_banded_melee_charging = false;
    game->pending_banded_melee_next_initiative = 0;
    game->pending_banded_melee_attacker_wounds = 0;
    game->pending_banded_melee_defender_wounds = 0;
    game->pending_banded_melee_pending_attacker_side = false;
    game->pending_banded_melee_resolved_initiative = 0;
}

static void begin_pending_banded_melee_resolution(
    game_t *game,
    const unit_t *attacker,
    const unit_t *target,
    follow_up_t follow_up,
    bool charging,
    int next_initiative,
    int attacker_wounds,
    int defender_wounds,
    bool pending_attacker_side,
    int resolved_initiative
) {
    if (game == NULL || attacker == NULL || target == NULL) {
        clear_pending_banded_melee_resolution(game);
        return;
    }

    game->pending_banded_melee_active = true;
    game->pending_banded_melee_attacker_id = attacker->id;
    game->pending_banded_melee_target_id = target->id;
    game->pending_banded_melee_follow_up = follow_up;
    game->pending_banded_melee_charging = charging;
    game->pending_banded_melee_next_initiative = next_initiative;
    game->pending_banded_melee_attacker_wounds = attacker_wounds;
    game->pending_banded_melee_defender_wounds = defender_wounds;
    game->pending_banded_melee_pending_attacker_side = pending_attacker_side;
    game->pending_banded_melee_resolved_initiative = resolved_initiative;
}

static void clear_pending_one_sided_melee_resolution(game_t *game) {
    if (game == NULL) {
        return;
    }

    game->pending_one_sided_melee_active = false;
    game->pending_one_sided_melee_acting_id = 0;
    game->pending_one_sided_melee_defending_id = 0;
    game->pending_one_sided_melee_charging = false;
    game->pending_one_sided_melee_next_initiative = 0;
    game->pending_one_sided_melee_accumulated_wounds = 0;
    game->pending_one_sided_melee_counts_for_attacker_score = false;
    game->pending_one_sided_melee_resolved_initiative = 0;
    game->pending_one_sided_melee_next_step = TE_PENDING_ONE_SIDED_MELEE_NONE;
    game->pending_one_sided_melee_assault_attacker_id = 0;
    game->pending_one_sided_melee_assault_target_id = 0;
    game->pending_one_sided_melee_follow_up = TE_FOLLOW_UP_ADVANCE;
    game->pending_one_sided_melee_attacker_wounds = 0;
    game->pending_one_sided_melee_defender_wounds = 0;
}

static void begin_pending_one_sided_melee_resolution(
    game_t *game,
    const unit_t *acting,
    const unit_t *defending,
    bool charging,
    int next_initiative,
    int accumulated_wounds,
    bool counts_for_attacker_score,
    int resolved_initiative,
    pending_one_sided_melee_step_t next_step,
    const unit_t *assault_attacker,
    const unit_t *assault_target,
    follow_up_t follow_up,
    int attacker_wounds,
    int defender_wounds
) {
    if (game == NULL || acting == NULL || defending == NULL || assault_attacker == NULL || assault_target == NULL) {
        clear_pending_one_sided_melee_resolution(game);
        return;
    }

    game->pending_one_sided_melee_active = true;
    game->pending_one_sided_melee_acting_id = acting->id;
    game->pending_one_sided_melee_defending_id = defending->id;
    game->pending_one_sided_melee_charging = charging;
    game->pending_one_sided_melee_next_initiative = next_initiative;
    game->pending_one_sided_melee_accumulated_wounds = accumulated_wounds;
    game->pending_one_sided_melee_counts_for_attacker_score = counts_for_attacker_score;
    game->pending_one_sided_melee_resolved_initiative = resolved_initiative;
    game->pending_one_sided_melee_next_step = next_step;
    game->pending_one_sided_melee_assault_attacker_id = assault_attacker->id;
    game->pending_one_sided_melee_assault_target_id = assault_target->id;
    game->pending_one_sided_melee_follow_up = follow_up;
    game->pending_one_sided_melee_attacker_wounds = attacker_wounds;
    game->pending_one_sided_melee_defender_wounds = defender_wounds;
}

static void clear_pending_simultaneous_melee_resolution(game_t *game) {
    if (game == NULL) {
        return;
    }

    game->pending_simultaneous_melee_active = false;
    game->pending_simultaneous_melee_attacker_id = 0;
    game->pending_simultaneous_melee_target_id = 0;
    game->pending_simultaneous_melee_follow_up = TE_FOLLOW_UP_ADVANCE;
    game->pending_simultaneous_melee_charging = false;
    game->pending_simultaneous_melee_resolved_initiative = 0;
    game->pending_simultaneous_melee_next_initiative = 0;
    game->pending_simultaneous_melee_attacker_wounds = 0;
    game->pending_simultaneous_melee_defender_wounds = 0;
    game->pending_simultaneous_melee_band_attacker_wounds = 0;
    game->pending_simultaneous_melee_band_defender_wounds = 0;
    game->pending_simultaneous_melee_pending_counts_for_attacker_score = false;
    game->pending_simultaneous_melee_step = TE_PENDING_SIMULTANEOUS_MELEE_NONE;
    game->pending_simultaneous_melee_counter_source_valid = false;
    memset(&game->pending_simultaneous_melee_counter_source, 0, sizeof(game->pending_simultaneous_melee_counter_source));
}

static void begin_pending_simultaneous_melee_resolution(
    game_t *game,
    const unit_t *attacker,
    const unit_t *target,
    follow_up_t follow_up,
    bool charging,
    int resolved_initiative,
    int next_initiative,
    int attacker_wounds,
    int defender_wounds,
    int band_attacker_wounds,
    int band_defender_wounds,
    bool pending_counts_for_attacker_score,
    pending_simultaneous_melee_step_t step,
    const unit_t *counter_source
) {
    if (game == NULL || attacker == NULL || target == NULL) {
        clear_pending_simultaneous_melee_resolution(game);
        return;
    }

    game->pending_simultaneous_melee_active = true;
    game->pending_simultaneous_melee_attacker_id = attacker->id;
    game->pending_simultaneous_melee_target_id = target->id;
    game->pending_simultaneous_melee_follow_up = follow_up;
    game->pending_simultaneous_melee_charging = charging;
    game->pending_simultaneous_melee_resolved_initiative = resolved_initiative;
    game->pending_simultaneous_melee_next_initiative = next_initiative;
    game->pending_simultaneous_melee_attacker_wounds = attacker_wounds;
    game->pending_simultaneous_melee_defender_wounds = defender_wounds;
    game->pending_simultaneous_melee_band_attacker_wounds = band_attacker_wounds;
    game->pending_simultaneous_melee_band_defender_wounds = band_defender_wounds;
    game->pending_simultaneous_melee_pending_counts_for_attacker_score = pending_counts_for_attacker_score;
    game->pending_simultaneous_melee_step = step;
    game->pending_simultaneous_melee_counter_source_valid = counter_source != NULL;
    if (counter_source != NULL) {
        game->pending_simultaneous_melee_counter_source = *counter_source;
    } else {
        memset(&game->pending_simultaneous_melee_counter_source, 0, sizeof(game->pending_simultaneous_melee_counter_source));
    }
}

static void clear_pending_vehicle_shot_sequence(game_t *game) {
    if (game == NULL) {
        return;
    }

    game->pending_vehicle_shot_active = false;
    game->pending_vehicle_shot_attacker_id = 0;
    game->pending_vehicle_shot_target_id = 0;
    game->pending_vehicle_shot_next_weapon_index = 0;
    game->pending_vehicle_shot_weapons_remaining = 0;
}

static void begin_pending_vehicle_shot_sequence(game_t *game, const unit_t *attacker, const unit_t *target, int next_weapon_index, int weapons_remaining) {
    if (game == NULL || attacker == NULL || target == NULL || weapons_remaining <= 0 || next_weapon_index >= attacker->weapon_count) {
        clear_pending_vehicle_shot_sequence(game);
        return;
    }

    game->pending_vehicle_shot_active = true;
    game->pending_vehicle_shot_attacker_id = attacker->id;
    game->pending_vehicle_shot_target_id = target->id;
    game->pending_vehicle_shot_next_weapon_index = next_weapon_index;
    game->pending_vehicle_shot_weapons_remaining = weapons_remaining;
}

static int collect_vehicle_weapon_destroy_indices(const unit_t *vehicle, int *out_indices) {
    if (vehicle == NULL) {
        return 0;
    }

    int count = 0;
    for (int index = 0; index < vehicle->weapon_count; index += 1) {
        if (vehicle->weapons[index].destroyed) {
            continue;
        }
        if (out_indices != NULL && count < TE_MAX_WEAPONS) {
            out_indices[count] = index;
        }
        count += 1;
    }
    return count;
}

static void destroy_vehicle_weapon_by_choice(game_t *game, const unit_t *chooser, unit_t *vehicle, int weapon_index, bool only_weapon_left) {
    if (game == NULL || vehicle == NULL || weapon_index < 0 || weapon_index >= vehicle->weapon_count) {
        return;
    }

    weapon_slot_t *slot = &vehicle->weapons[weapon_index];
    slot->destroyed = true;
    if (chooser != NULL) {
        if (only_weapon_left) {
            te_log(game, "%s chooses %s on %s; it was the only weapon left.", chooser->name, slot->profile.name, vehicle->name);
        } else {
            te_log(game, "%s chooses %s on %s for the Weapon Destroyed result.", chooser->name, slot->profile.name, vehicle->name);
        }
    } else if (only_weapon_left) {
        te_log(game, "%s loses %s; it was the only weapon left.", vehicle->name, slot->profile.name);
    } else {
        te_log(game, "%s loses %s.", vehicle->name, slot->profile.name);
    }
}

static void handle_weapon_destroy_result(game_t *game, const unit_t *chooser, unit_t *vehicle, const char *no_weapon_reason) {
    if (game == NULL || vehicle == NULL) {
        return;
    }

    int option_indices[TE_MAX_WEAPONS];
    int option_count = collect_vehicle_weapon_destroy_indices(vehicle, option_indices);
    if (option_count <= 0) {
        destroy_unit(game, vehicle, no_weapon_reason);
        return;
    }

    if (option_count == 1) {
        destroy_vehicle_weapon_by_choice(game, chooser, vehicle, option_indices[0], true);
        return;
    }

    clear_pending_weapon_destroy_choice(game);
    game->pending_weapon_destroy_active = true;
    game->pending_weapon_destroy_chooser_id = chooser != NULL ? chooser->id : 0;
    game->pending_weapon_destroy_target_id = vehicle->id;
    game->pending_weapon_destroy_option_count = option_count;
    memcpy(game->pending_weapon_destroy_option_indices, option_indices, (size_t)option_count * sizeof(int));

    const char *chooser_name = chooser != NULL ? chooser->name : "The attacker";
    te_log(game, "%s scores Weapon Destroyed on %s; %s chooses which weapon is lost.", chooser_name, vehicle->name, chooser_name);
}

static bool assert_no_pending_weapon_destroy_choice(game_t *game) {
    if (!game_has_pending_weapon_destroy_choice(game)) {
        return true;
    }

    const unit_t *chooser = find_unit_const(game, game->pending_weapon_destroy_chooser_id);
    const unit_t *target = find_unit_const(game, game->pending_weapon_destroy_target_id);
    const char *chooser_name = chooser != NULL ? chooser->name : "The attacking unit";
    const char *target_name = target != NULL ? target->name : "the damaged vehicle";
    return fail(game, "Resolve %s's weapon-destroyed choice on %s first.", chooser_name, target_name);
}

static bool assert_no_pending_resolution_choice(game_t *game) {
    if (game_has_pending_weapon_destroy_choice(game)) {
        return assert_no_pending_weapon_destroy_choice(game);
    }
    if (!game_has_pending_hit_allocation_choice(game)) {
        return true;
    }

    const unit_t *target = find_unit_const(game, game->pending_hit_allocation_target_id);
    const char *attacker_name = game->pending_hit_allocation_attacker_name != NULL ? game->pending_hit_allocation_attacker_name : "The attacker";
    const char *target_name = target != NULL ? target->name : "the mixed-profile unit";
    return fail(game, "Resolve %s's mixed-profile hit allocation on %s first.", attacker_name, target_name);
}

static bool unit_uses_vehicle_rules(const unit_t *unit) {
    return unit != NULL && (unit->kind == TE_UNIT_VEHICLE || unit->kind == TE_UNIT_ASSAULT_GUN);
}

static bool unit_is_transport(const unit_t *unit) {
    return unit != NULL && unit->kind == TE_UNIT_VEHICLE && unit->transport_capacity > 0;
}

static bool unit_is_embarked(const unit_t *unit) {
    return unit != NULL && unit->embarked_in_transport_id > 0;
}

static int objective_presence_value(const unit_t *unit) {
    if (unit == NULL || unit->models <= 0) {
        return 0;
    }
    if (unit_uses_vehicle_rules(unit)) {
        return 2;
    }
    if (unit->models > 3) {
        return 3;
    }
    return unit->models < 1 ? 1 : unit->models;
}

static player_t evaluate_objective(const game_t *game, const objective_t *objective, int *out_player_one_presence, int *out_player_two_presence) {
    int player_one_presence = 0;
    int player_two_presence = 0;

    if (game != NULL && objective != NULL) {
        for (int index = 0; index < game->unit_count; index += 1) {
            const unit_t *unit = &game->units[index];
            if (unit->destroyed || unit->falling_back || unit_is_embarked(unit)) {
                continue;
            }

            float distance = te_distance(unit->x, unit->y, objective->x, objective->y);
            if (distance > objective->radius + unit->footprint_radius) {
                continue;
            }

            int value = objective_presence_value(unit);
            if (unit->owner == TE_PLAYER_ONE) {
                player_one_presence += value;
            } else if (unit->owner == TE_PLAYER_TWO) {
                player_two_presence += value;
            }
        }
    }

    if (out_player_one_presence != NULL) {
        *out_player_one_presence = player_one_presence;
    }
    if (out_player_two_presence != NULL) {
        *out_player_two_presence = player_two_presence;
    }

    if (player_one_presence == player_two_presence) {
        return TE_PLAYER_NONE;
    }
    return player_one_presence > player_two_presence ? TE_PLAYER_ONE : TE_PLAYER_TWO;
}

static bool unit_has_profile_groups(const unit_t *unit) {
    return unit != NULL && unit->profile_group_count > 0;
}

static bool unit_has_mixed_profiles(const unit_t *unit) {
    return unit != NULL && unit->profile_group_count > 1;
}

static int te_wounds_per_model(const unit_t *unit) {
    return unit != NULL && unit->wounds_per_model > 0 ? unit->wounds_per_model : 1;
}

static int profile_group_wounds_per_model(const profile_group_t *group) {
    return group != NULL && group->wounds_per_model > 0 ? group->wounds_per_model : 1;
}

static int profile_group_weapon_skill(const unit_t *unit, const profile_group_t *group) {
    if (group != NULL && group->weapon_skill > 0) {
        return group->weapon_skill;
    }
    return unit != NULL ? unit->weapon_skill : 0;
}

static int profile_group_ballistic_skill(const unit_t *unit, const profile_group_t *group) {
    if (group != NULL && group->ballistic_skill > 0) {
        return group->ballistic_skill;
    }
    return unit != NULL ? unit->ballistic_skill : 0;
}

static int profile_group_strength(const unit_t *unit, const profile_group_t *group) {
    if (group != NULL && group->strength > 0) {
        return group->strength;
    }
    return unit != NULL ? unit->strength : 0;
}

static int profile_group_initiative(const unit_t *unit, const profile_group_t *group) {
    if (group != NULL && group->initiative > 0) {
        return group->initiative;
    }
    return unit != NULL ? unit->initiative : 0;
}

static int profile_group_attacks(const unit_t *unit, const profile_group_t *group) {
    if (group != NULL && group->attacks > 0) {
        return group->attacks;
    }
    return unit != NULL ? unit->attacks : 0;
}

static int profile_group_leadership(const unit_t *unit, const profile_group_t *group) {
    if (group != NULL && group->leadership > 0) {
        return group->leadership;
    }
    return unit != NULL ? unit->leadership : 0;
}

static void normalize_profile_group(profile_group_t *group) {
    if (group == NULL) {
        return;
    }

    group->wounds_per_model = profile_group_wounds_per_model(group);
    if (group->models <= 0) {
        group->lead_model_wounds = 0;
        return;
    }

    if (group->lead_model_wounds <= 0 || group->lead_model_wounds > group->wounds_per_model) {
        group->lead_model_wounds = group->wounds_per_model;
    }
}

static int profile_group_total_wounds_remaining(const profile_group_t *group) {
    if (group == NULL || group->models <= 0) {
        return 0;
    }

    int wounds_per_model = profile_group_wounds_per_model(group);
    int lead_model_wounds = group->lead_model_wounds;
    if (lead_model_wounds <= 0 || lead_model_wounds > wounds_per_model) {
        lead_model_wounds = wounds_per_model;
    }

    return (group->models - 1) * wounds_per_model + lead_model_wounds;
}

static void sync_unit_from_profile_groups(unit_t *unit) {
    if (unit == NULL || !unit_has_profile_groups(unit)) {
        return;
    }

    int total_models = 0;
    int total_starting_models = 0;
    int representative_index = -1;
    for (int index = 0; index < unit->profile_group_count; index += 1) {
        profile_group_t *group = &unit->profile_groups[index];
        normalize_profile_group(group);
        total_models += group->models;
        total_starting_models += group->starting_models;

        if (group->models <= 0) {
            continue;
        }

        if (representative_index < 0) {
            representative_index = index;
            continue;
        }

        const profile_group_t *best = &unit->profile_groups[representative_index];
        if (group->models > best->models ||
            (group->models == best->models && group->toughness < best->toughness) ||
            (group->models == best->models && group->toughness == best->toughness && group->save > best->save)) {
            representative_index = index;
        }
    }

    unit->models = total_models;
    unit->starting_models = total_starting_models;
    if (representative_index >= 0) {
        const profile_group_t *group = &unit->profile_groups[representative_index];
        unit->weapon_skill = profile_group_weapon_skill(unit, group);
        unit->ballistic_skill = profile_group_ballistic_skill(unit, group);
        unit->strength = profile_group_strength(unit, group);
        unit->toughness = group->toughness;
        unit->initiative = profile_group_initiative(unit, group);
        unit->attacks = profile_group_attacks(unit, group);
        unit->leadership = profile_group_leadership(unit, group);
        unit->save = group->save;
        unit->wounds_per_model = group->wounds_per_model;
        unit->lead_model_wounds = group->lead_model_wounds;
    } else {
        unit->lead_model_wounds = 0;
    }
}

static void normalize_unit_wounds(unit_t *unit) {
    if (unit == NULL) {
        return;
    }

    if (unit_has_profile_groups(unit)) {
        sync_unit_from_profile_groups(unit);
        return;
    }

    unit->wounds_per_model = te_wounds_per_model(unit);
    if (unit->destroyed || unit->models <= 0) {
        unit->lead_model_wounds = 0;
        return;
    }

    if (unit->lead_model_wounds <= 0 || unit->lead_model_wounds > unit->wounds_per_model) {
        unit->lead_model_wounds = unit->wounds_per_model;
    }
}

static int te_total_wounds_remaining(const unit_t *unit) {
    if (unit == NULL || unit->destroyed || unit->models <= 0) {
        return 0;
    }

    if (unit_has_profile_groups(unit)) {
        int total = 0;
        for (int index = 0; index < unit->profile_group_count; index += 1) {
            total += profile_group_total_wounds_remaining(&unit->profile_groups[index]);
        }
        return total;
    }

    int wounds_per_model = te_wounds_per_model(unit);
    int lead_model_wounds = unit->lead_model_wounds;
    if (lead_model_wounds <= 0 || lead_model_wounds > wounds_per_model) {
        lead_model_wounds = wounds_per_model;
    }

    return (unit->models - 1) * wounds_per_model + lead_model_wounds;
}

static float edge_distance_between_units(const unit_t *left, const unit_t *right) {
    return te_distance(left->x, left->y, right->x, right->y) - left->footprint_radius - right->footprint_radius;
}

static unit_t *embarked_unit(game_t *game, const unit_t *transport) {
    if (game == NULL || !unit_is_transport(transport) || transport->embarked_unit_id <= 0) {
        return NULL;
    }
    return find_unit(game, transport->embarked_unit_id);
}

static void sync_embarked_unit_position(game_t *game, unit_t *transport) {
    unit_t *passenger = embarked_unit(game, transport);
    if (passenger == NULL) {
        return;
    }

    passenger->x = transport->x;
    passenger->y = transport->y;
    passenger->facing_degrees = transport->facing_degrees;
}

static void set_starting_embarkation(game_t *game, player_t owner, const char *passenger_name, const char *transport_name) {
    unit_t *passenger = find_unit_by_owner_and_name(game, owner, passenger_name);
    unit_t *transport = find_unit_by_owner_and_name(game, owner, transport_name);
    if (passenger == NULL || transport == NULL || !unit_is_transport(transport)) {
        return;
    }
    if (passenger->destroyed || transport->destroyed || passenger->owner != transport->owner) {
        return;
    }
    if (transport->transport_capacity < passenger->models) {
        return;
    }

    transport->embarked_unit_id = passenger->id;
    passenger->embarked_in_transport_id = transport->id;
    passenger->embarked_this_turn = false;
    passenger->moved_this_turn = false;
    passenger->movement_action_used_this_turn = false;
    sync_embarked_unit_position(game, transport);
}

static int cover_save_for_unit(const game_t *game, const unit_t *unit) {
    int best_save = 0;
    if (unit->manual_in_cover) {
        best_save = 5;
    }

    for (int index = 0; index < game->zone_count; index += 1) {
        const zone_t *zone = &game->zones[index];
        if (zone->cover_save > 0 && point_in_rect(unit->x, unit->y, zone->rect)) {
            if (best_save == 0 || zone->cover_save < best_save) {
                best_save = zone->cover_save;
            }
        }
    }

    return best_save;
}

static bool hull_down_for_unit(const game_t *game, const unit_t *unit) {
    if (unit->manual_hull_down) {
        return true;
    }

    for (int index = 0; index < game->zone_count; index += 1) {
        const zone_t *zone = &game->zones[index];
        if (zone->hull_down && point_in_rect(unit->x, unit->y, zone->rect)) {
            return true;
        }
    }

    return false;
}

static bool line_of_sight_blocked(const game_t *game, const unit_t *attacker, const unit_t *target) {
    for (int index = 0; index < game->zone_count; index += 1) {
        const zone_t *zone = &game->zones[index];
        if (!zone->blocks_line_of_sight) {
            continue;
        }

        bool attacker_inside = point_in_rect(attacker->x, attacker->y, zone->rect);
        bool target_inside = point_in_rect(target->x, target->y, zone->rect);
        if (attacker_inside || target_inside) {
            continue;
        }

        if (segment_intersects_rect(attacker->x, attacker->y, target->x, target->y, zone->rect)) {
            return true;
        }
    }

    if (!unit_uses_vehicle_rules(attacker)) {
        return false;
    }

    for (int index = 0; index < game->unit_count; index += 1) {
        const unit_t *blocker = &game->units[index];
        if (blocker->destroyed || unit_is_embarked(blocker) || blocker->id == attacker->id || blocker->id == target->id || !unit_uses_vehicle_rules(blocker)) {
            continue;
        }

        if (segment_intersects_circle(attacker->x, attacker->y, target->x, target->y, blocker->x, blocker->y, blocker->footprint_radius)) {
            return true;
        }
    }

    return false;
}

static bool weapon_slot_can_bear_target(const unit_t *attacker, const unit_t *target, const weapon_slot_t *slot) {
    if (!unit_uses_vehicle_rules(attacker)) {
        return true;
    }

    float angle_to_target = angle_to(attacker->x, attacker->y, target->x, target->y);
    if (slot->jammed_in_place) {
        return shared_angle_within_arc(slot->jammed_fire_angle_degrees, angle_to_target, (float)TE_JAMMED_WEAPON_ARC_DEGREES);
    }

    if (slot->profile.fire_arc_degrees <= 0 || slot->profile.fire_arc_degrees >= 360) {
        return true;
    }

    return shared_angle_within_arc(attacker->facing_degrees, angle_to_target, (float)slot->profile.fire_arc_degrees);
}

static bool transport_passenger_has_arc(const unit_t *transport, const unit_t *target) {
    if (transport->open_topped) {
        return true;
    }

    float angle_to_target = angle_to(transport->x, transport->y, target->x, target->y);
    return shared_angle_within_arc(transport->facing_degrees, angle_to_target, 180.0f);
}

static bool unit_is_crew_stunned_assault_gun(const unit_t *unit) {
    return unit != NULL && unit->kind == TE_UNIT_ASSAULT_GUN && unit->crew_stunned;
}

static void log_stunned_assault_gun_close_combat_skip(game_t *game, const unit_t *assault_gun) {
    if (game == NULL || !unit_is_crew_stunned_assault_gun(assault_gun)) {
        return;
    }

    te_log(game, "%s is crew stunned and cannot fight in close combat this turn.", assault_gun->name);
}

static bool enemy_within_distance(const game_t *game, const unit_t *unit, float range) {
    for (int index = 0; index < game->unit_count; index += 1) {
        const unit_t *enemy = &game->units[index];
        if (enemy->owner == unit->owner || enemy->destroyed || unit_is_embarked(enemy)) {
            continue;
        }
        float edge_distance = te_distance(unit->x, unit->y, enemy->x, enemy->y) - unit->footprint_radius - enemy->footprint_radius;
        if (edge_distance < range) {
            return true;
        }
    }
    return false;
}

static int required_to_hit_ballistic(int ballistic_skill) {
    if (ballistic_skill <= 0) {
        return 7;
    }
    if (ballistic_skill >= 5) {
        return 2;
    }
    return 7 - ballistic_skill;
}

int shared_adapter_required_to_wound(int strength, int toughness) {
    if (strength <= 0) {
        return 7;
    }
    if (strength >= toughness + 2) {
        return 2;
    }
    if (strength == toughness + 1) {
        return 3;
    }
    if (strength == toughness) {
        return 4;
    }
    if (strength + 1 == toughness) {
        return 5;
    }
    if (strength + 2 == toughness) {
        return 6;
    }
    return 7;
}

static int required_to_wound(int strength, int toughness) {
    return shared_required_to_wound(strength, toughness);
}

static int required_to_hit_melee(int attacker_ws, int defender_ws) {
    if (defender_ws <= 0) {
        return 3;
    }
    if (attacker_ws > defender_ws) {
        return 3;
    }
    if (attacker_ws == defender_ws) {
        return 4;
    }
    if (attacker_ws * 2 <= defender_ws) {
        return 5;
    }
    return 4;
}

static bool roll_save(game_t *game, int save) {
    if (save <= 0 || save > 6) {
        return false;
    }
    return roll_d6(game) >= save;
}

static int armour_save_only(const unit_t *unit) {
    return unit != NULL && unit->save > 0 ? unit->save : 0;
}

static int profile_group_save_rank(const profile_group_t *group) {
    if (group == NULL || group->save <= 0) {
        return 7;
    }
    return group->save;
}

static void sorted_profile_group_indices(const unit_t *unit, int *indices, int *count) {
    int used = 0;
    if (unit == NULL || indices == NULL || count == NULL) {
        return;
    }

    for (int index = 0; index < unit->profile_group_count; index += 1) {
        if (unit->profile_groups[index].models <= 0) {
            continue;
        }
        indices[used] = index;
        used += 1;
    }

    for (int left = 0; left < used; left += 1) {
        for (int right = left + 1; right < used; right += 1) {
            const profile_group_t *a = &unit->profile_groups[indices[left]];
            const profile_group_t *b = &unit->profile_groups[indices[right]];

            bool swap = false;
            if (a->toughness != b->toughness) {
                swap = a->toughness > b->toughness;
            } else if (profile_group_save_rank(a) != profile_group_save_rank(b)) {
                swap = profile_group_save_rank(a) < profile_group_save_rank(b);
            } else if (profile_group_wounds_per_model(a) != profile_group_wounds_per_model(b)) {
                swap = profile_group_wounds_per_model(a) > profile_group_wounds_per_model(b);
            } else if (a->models != b->models) {
                swap = a->models < b->models;
            }

            if (swap) {
                int temp = indices[left];
                indices[left] = indices[right];
                indices[right] = temp;
            }
        }
    }

    *count = used;
}

static void order_profile_group_indices_for_casualties(const unit_t *unit, int *indices, int *count) {
    sorted_profile_group_indices(unit, indices, count);
    if (unit == NULL || indices == NULL || count == NULL || *count <= 1) {
        return;
    }

    int preferred_index = unit->preferred_casualty_group_index;
    if (preferred_index < 0 || preferred_index >= unit->profile_group_count) {
        return;
    }
    if (unit->profile_groups[preferred_index].models <= 0) {
        return;
    }

    int preferred_order = -1;
    for (int index = 0; index < *count; index += 1) {
        if (indices[index] == preferred_index) {
            preferred_order = index;
            break;
        }
    }

    if (preferred_order <= 0) {
        return;
    }

    int selected = indices[preferred_order];
    for (int index = preferred_order; index > 0; index -= 1) {
        indices[index] = indices[index - 1];
    }
    indices[0] = selected;
}

static void allocate_hits_to_profile_groups(const unit_t *unit, int hits, int *out_hits_by_group) {
    if (unit == NULL || out_hits_by_group == NULL || hits <= 0) {
        return;
    }

    memset(out_hits_by_group, 0, sizeof(int) * TE_MAX_PROFILE_GROUPS);

    int indices[TE_MAX_PROFILE_GROUPS];
    int index_count = 0;
    order_profile_group_indices_for_casualties(unit, indices, &index_count);
    if (index_count <= 0) {
        return;
    }

    int allocated = 0;
    int rounds = 0;
    while (allocated < hits) {
        bool progress = false;
        for (int order = 0; order < index_count && allocated < hits; order += 1) {
            int group_index = indices[order];
            const profile_group_t *group = &unit->profile_groups[group_index];
            if (out_hits_by_group[group_index] >= (rounds + 1) * group->models) {
                continue;
            }
            out_hits_by_group[group_index] += 1;
            allocated += 1;
            progress = true;
        }

        if (!progress) {
            break;
        }
        rounds += 1;
    }
}

static int live_profile_group_count(const unit_t *unit) {
    if (unit == NULL) {
        return 0;
    }

    int live_groups = 0;
    for (int index = 0; index < unit->profile_group_count; index += 1) {
        if (unit->profile_groups[index].models > 0) {
            live_groups += 1;
        }
    }
    return live_groups;
}

static int total_allocated_mixed_hits(const int *allocated_hits) {
    if (allocated_hits == NULL) {
        return 0;
    }

    int total = 0;
    for (int index = 0; index < TE_MAX_PROFILE_GROUPS; index += 1) {
        total += allocated_hits[index];
    }
    return total;
}

static bool pending_hit_allocation_group_can_accept(const unit_t *target, const int *allocated_hits, int group_index) {
    if (target == NULL || allocated_hits == NULL || group_index < 0 || group_index >= target->profile_group_count) {
        return false;
    }

    const profile_group_t *group = &target->profile_groups[group_index];
    if (group->models <= 0 || target->models <= 0) {
        return false;
    }

    int rounds_completed = total_allocated_mixed_hits(allocated_hits) / target->models;
    return allocated_hits[group_index] < (rounds_completed + 1) * group->models;
}

static int choose_profile_group_save_with_weapon(const game_t *game, const unit_t *unit, const profile_group_t *group, const weapon_profile_t *weapon) {
    int armour_save = 0;
    if (group->save > 0 && (weapon->ap <= 0 || weapon->ap > group->save)) {
        armour_save = group->save;
    }

    if (!weapon->ignores_cover) {
        int cover_save = cover_save_for_unit(game, unit);
        if (cover_save > 0 && (armour_save == 0 || cover_save < armour_save)) {
            armour_save = cover_save;
        }
    }

    return armour_save;
}

static int apply_profile_group_damage(game_t *game, const unit_t *unit, profile_group_t *group, int wounds, bool instant_death, const char *source_name, int *out_models_lost) {
    if (out_models_lost != NULL) {
        *out_models_lost = 0;
    }
    if (group == NULL || wounds <= 0 || group->models <= 0) {
        return 0;
    }

    normalize_profile_group(group);
    int applied = wounds;
    int total_wounds = instant_death ? group->models : profile_group_total_wounds_remaining(group);
    if (applied > total_wounds) {
        applied = total_wounds;
    }

    int models_lost = 0;
    if (instant_death) {
        models_lost = applied;
        group->models -= applied;
        if (group->models <= 0) {
            group->models = 0;
            group->lead_model_wounds = 0;
        }
    } else {
        int remaining = applied;
        while (remaining > 0 && group->models > 0) {
            if (remaining < group->lead_model_wounds) {
                group->lead_model_wounds -= remaining;
                remaining = 0;
                break;
            }

            remaining -= group->lead_model_wounds;
            group->models -= 1;
            models_lost += 1;
            if (group->models > 0) {
                group->lead_model_wounds = group->wounds_per_model;
            } else {
                group->lead_model_wounds = 0;
            }
        }
    }

    if (out_models_lost != NULL) {
        *out_models_lost = models_lost;
    }

    if (instant_death) {
        te_log(game, "%s in %s suffers %d instant-kill wound%s from %s, losing %d model%s.", group->name, unit->name, applied, applied == 1 ? "" : "s", source_name, models_lost, models_lost == 1 ? "" : "s");
    } else if (profile_group_wounds_per_model(group) <= 1) {
        te_log(game, "%s in %s loses %d model%s to %s.", group->name, unit->name, models_lost, models_lost == 1 ? "" : "s", source_name);
    } else if (models_lost <= 0) {
        te_log(game, "%s in %s suffers %d unsaved wound%s from %s; the lead model is reduced to %d/%d wounds.", group->name, unit->name, applied, applied == 1 ? "" : "s", source_name, group->lead_model_wounds, group->wounds_per_model);
    } else if (group->models > 0 && group->lead_model_wounds < group->wounds_per_model) {
        te_log(game, "%s in %s suffers %d unsaved wound%s from %s, losing %d model%s and leaving the lead model on %d/%d wounds.", group->name, unit->name, applied, applied == 1 ? "" : "s", source_name, models_lost, models_lost == 1 ? "" : "s", group->lead_model_wounds, group->wounds_per_model);
    } else {
        te_log(game, "%s in %s suffers %d unsaved wound%s from %s, losing %d model%s.", group->name, unit->name, applied, applied == 1 ? "" : "s", source_name, models_lost, models_lost == 1 ? "" : "s");
    }

    return applied;
}

static player_t other_player(player_t player) {
    return player == TE_PLAYER_ONE ? TE_PLAYER_TWO : TE_PLAYER_ONE;
}

static int next_turn_number_for_player(const game_t *game, player_t player) {
    if (game == NULL) {
        return 0;
    }
    if (player == TE_PLAYER_NONE) {
        return game->turn_number + 1;
    }
    return game->active_player == player ? game->turn_number + 2 : game->turn_number + 1;
}

static const char *player_name(player_t player) {
    return player == TE_PLAYER_ONE ? "Player 1" : "Player 2";
}

static const char *phase_name(phase_t phase) {
    switch (phase) {
        case TE_PHASE_MOVEMENT:
            return "Movement";
        case TE_PHASE_SHOOTING:
            return "Shooting";
        case TE_PHASE_ASSAULT:
            return "Assault";
        default:
            return "Unknown";
    }
}

static player_t mission_winner(const game_t *game) {
    if (game == NULL) {
        return TE_PLAYER_NONE;
    }
    if (game->player_one_score >= game->mission_target_score && game->player_one_score > game->player_two_score) {
        return TE_PLAYER_ONE;
    }
    if (game->player_two_score >= game->mission_target_score && game->player_two_score > game->player_one_score) {
        return TE_PLAYER_TWO;
    }
    return TE_PLAYER_NONE;
}

static void log_mission_briefing(game_t *game) {
    if (game == NULL || game->mission_name == NULL || game->mission_target_score <= 0) {
        return;
    }
    te_log(game, "Mission: %s. Score 1 VP per controlled objective at the end of each player's turn. First to %d VP wins.", game->mission_name, game->mission_target_score);
}

static void score_objectives(game_t *game) {
    if (game == NULL || mission_winner(game) != TE_PLAYER_NONE) {
        return;
    }

    int player_one_gain = 0;
    int player_two_gain = 0;
    player_t previous_winner = mission_winner(game);

    for (int index = 0; index < game->objective_count; index += 1) {
        player_t controller = evaluate_objective(game, &game->objectives[index], NULL, NULL);
        if (controller == TE_PLAYER_ONE) {
            player_one_gain += 1;
        } else if (controller == TE_PLAYER_TWO) {
            player_two_gain += 1;
        }
    }

    if (player_one_gain == 0 && player_two_gain == 0) {
        te_log(game, "Mission: No objective points scored at end of turn %d.", game->turn_number);
        return;
    }

    if (player_one_gain > 0) {
        game->player_one_score += player_one_gain;
        te_log(game, "Mission: Player 1 scores %d VP from objective control.", player_one_gain);
    }
    if (player_two_gain > 0) {
        game->player_two_score += player_two_gain;
        te_log(game, "Mission: Player 2 scores %d VP from objective control.", player_two_gain);
    }

    player_t winner = mission_winner(game);
    if (previous_winner == TE_PLAYER_NONE && winner != TE_PLAYER_NONE) {
        te_log(game, "Mission: %s reaches %d VP and wins %s.", player_name(winner), game->mission_target_score, game->mission_name);
    }
}

static void clear_locked_state(unit_t *unit) {
    shared_clear_locked_state(NULL, (shared_unit_t *)unit, NULL);
}

void shared_adapter_clear_locked_state(shared_game_t *game, shared_unit_t *first, shared_unit_t *second) {
    (void)game;
    (void)second;

    unit_t *unit = (unit_t *)first;
    if (unit == NULL) {
        return;
    }
    unit->locked_in_assault = false;
    unit->locked_with = -1;
}

static void set_unit_crew_shaken_until_next_turn(const game_t *game, unit_t *unit) {
    if (game == NULL || unit == NULL || !unit_uses_vehicle_rules(unit)) {
        return;
    }

    int next_turn = next_turn_number_for_player(game, unit->owner);
    unit->crew_shaken = true;
    if (unit->crew_shaken_until_turn < next_turn) {
        unit->crew_shaken_until_turn = next_turn;
    }
}

static void set_unit_crew_stunned_until_next_turn(const game_t *game, unit_t *unit) {
    if (game == NULL || unit == NULL || !unit_uses_vehicle_rules(unit)) {
        return;
    }

    int next_turn = next_turn_number_for_player(game, unit->owner);
    unit->crew_stunned = true;
    if (unit->crew_stunned_until_turn < next_turn) {
        unit->crew_stunned_until_turn = next_turn;
    }
}

static void pin_unit_until_next_turn(const game_t *game, unit_t *unit) {
    if (game == NULL || unit == NULL || unit->destroyed || unit_uses_vehicle_rules(unit) || unit->falling_back) {
        return;
    }

    int next_turn = next_turn_number_for_player(game, unit->owner);
    if (unit->pinned_until_turn < next_turn) {
        unit->pinned_until_turn = next_turn;
    }
}

static void resolve_destroyed_transport_passengers(game_t *game, unit_t *transport, bool annihilate_passengers) {
    unit_t *passenger = embarked_unit(game, transport);
    if (passenger == NULL || passenger->destroyed) {
        transport->embarked_unit_id = 0;
        return;
    }

    transport->embarked_unit_id = 0;
    passenger->embarked_in_transport_id = 0;
    passenger->embarked_this_turn = false;

    if (annihilate_passengers) {
        destroy_unit(game, passenger, "its transport was annihilated by ordnance");
        return;
    }

    int passenger_wounds = 0;
    for (int model = 0; model < passenger->models; model += 1) {
        if (roll_d6(game) < 4) {
            continue;
        }

        int save = armour_save_only(passenger);
        if (save > 0 && roll_save(game, save)) {
            continue;
        }
        passenger_wounds += 1;
    }

    if (passenger_wounds > 0) {
        apply_infantry_damage(game, passenger, passenger_wounds, 0, "the transport's destruction", false, NULL);
        if (passenger->destroyed) {
            return;
        }
    }

    float disembark_x = transport->x;
    float disembark_y = transport->y;
    if (!find_disembark_position(game, transport, passenger, &disembark_x, &disembark_y)) {
        destroy_unit(game, passenger, "its transport was destroyed before it could disembark");
        return;
    }

    passenger->x = disembark_x;
    passenger->y = disembark_y;
    passenger->facing_degrees = transport->facing_degrees;
    passenger->moved_this_turn = true;
    passenger->movement_action_used_this_turn = true;
    passenger->shot_this_turn = true;
    passenger->assaulted_this_turn = true;
    pin_unit_until_next_turn(game, passenger);
    te_log(game, "%s makes an emergency disembarkation from the destroyed %s and is pinned by the wreck.", passenger->name, transport->name);
}

static void destroy_unit(game_t *game, unit_t *unit, const char *reason) {
    shared_destroy_unit((shared_game_t *)game, (shared_unit_t *)unit, reason);
}

void shared_adapter_destroy_unit(shared_game_t *game, shared_unit_t *unit, const char *reason) {
    destroy_unit_with_passenger_outcome((game_t *)game, (unit_t *)unit, reason, false);
}

static void destroy_unit_with_passenger_outcome(game_t *game, unit_t *unit, const char *reason, bool annihilate_embarked_units) {
    if (unit_is_transport(unit) && unit->embarked_unit_id > 0) {
        resolve_destroyed_transport_passengers(game, unit, annihilate_embarked_units);
    }

    unit->destroyed = true;
    unit->models = 0;
    unit->lead_model_wounds = 0;
    unit->falling_back = false;
    unit->transport_capacity = 0;
    unit->embarked_unit_id = 0;
    unit->embarked_in_transport_id = 0;
    unit->embarked_this_turn = false;
    clear_locked_state(unit);
    te_log(game, "%s is removed from play (%s).", unit->name, reason);
}

static void move_toward_point(unit_t *unit, float target_x, float target_y, float distance) {
    float dx = target_x - unit->x;
    float dy = target_y - unit->y;
    float length = hypotf(dx, dy);
    if (length < 0.001f) {
        return;
    }

    unit->x += dx / length * distance;
    unit->y += dy / length * distance;
}

static void resolve_fall_back(game_t *game, unit_t *unit, int distance) {
    unit->falling_back = true;
    clear_locked_state(unit);

    float destination_x = unit->x;
    if (unit->owner == TE_PLAYER_ONE) {
        destination_x -= (float)distance;
    } else {
        destination_x += (float)distance;
    }

    if (destination_x < 0.0f || destination_x > TE_BOARD_WIDTH) {
        destroy_unit(game, unit, "fell back off the table");
        return;
    }

    unit->x = fminf(fmaxf(destination_x, unit->footprint_radius), TE_BOARD_WIDTH - unit->footprint_radius);
    te_log(game, "%s falls back %d\" toward %s's board edge.", unit->name, distance, player_name(unit->owner));
}

static int best_movement_allowance(game_t *game, const unit_t *unit, bool difficult_terrain) {
    if (unit->kind == TE_UNIT_ASSAULT_GUN) {
        return difficult_terrain ? roll_highest_of_2d6(game) : 6;
    }

    if (unit->kind == TE_UNIT_VEHICLE) {
        return unit->fast ? 24 : 12;
    }

    return difficult_terrain ? roll_highest_of_2d6(game) : 6;
}

static bool path_touches_terrain(const game_t *game, float x1, float y1, float x2, float y2, terrain_kind_t kind) {
    for (int index = 0; index < game->zone_count; index += 1) {
        const zone_t *zone = &game->zones[index];
        if (zone->kind != kind) {
            continue;
        }
        if (segment_intersects_rect(x1, y1, x2, y2, zone->rect)) {
            return true;
        }
    }
    return false;
}

static bool can_place_unit_at(const game_t *game, const unit_t *unit, float x, float y, int ignore_unit_id) {
    if (x < unit->footprint_radius || y < unit->footprint_radius || x > TE_BOARD_WIDTH - unit->footprint_radius || y > TE_BOARD_HEIGHT - unit->footprint_radius) {
        return false;
    }

    if (path_touches_terrain(game, x, y, x, y, TE_TERRAIN_IMPASSABLE)) {
        return false;
    }

    for (int index = 0; index < game->unit_count; index += 1) {
        const unit_t *other = &game->units[index];
        if (other->destroyed || other->id == unit->id || other->id == ignore_unit_id || unit_is_embarked(other)) {
            continue;
        }

        float separation = te_distance(x, y, other->x, other->y) - unit->footprint_radius - other->footprint_radius;
        if (other->owner != unit->owner && separation < 1.0f) {
            return false;
        }
        if (other->owner == unit->owner && separation < 0.25f) {
            return false;
        }
    }

    return true;
}

static bool find_disembark_position(const game_t *game, const unit_t *transport, const unit_t *unit, float *out_x, float *out_y) {
    static const float offsets[] = {0.0f, 35.0f, -35.0f, 90.0f, -90.0f, 145.0f, -145.0f, 180.0f};
    for (float edge_clearance = 1.0f; edge_clearance <= 2.0f + 0.001f; edge_clearance += 0.25f) {
        float radius = transport->footprint_radius + unit->footprint_radius + edge_clearance;
        for (int index = 0; index < (int)(sizeof(offsets) / sizeof(offsets[0])); index += 1) {
            float angle = normalize_angle(transport->facing_degrees + offsets[index]) * ((float)M_PI / 180.0f);
            float candidate_x = transport->x + cosf(angle) * radius;
            float candidate_y = transport->y + sinf(angle) * radius;
            if (!can_place_unit_at(game, unit, candidate_x, candidate_y, transport->id)) {
                continue;
            }

            *out_x = candidate_x;
            *out_y = candidate_y;
            return true;
        }
    }

    return false;
}

static float move_toward_point_legally(const game_t *game, unit_t *unit, float target_x, float target_y, float distance, int ignore_unit_id) {
    if (game == NULL || unit == NULL || unit->destroyed || distance <= 0.0f) {
        return 0.0f;
    }

    float dx = target_x - unit->x;
    float dy = target_y - unit->y;
    float length = hypotf(dx, dy);
    if (length < 0.001f) {
        return 0.0f;
    }

    float direction_x = dx / length;
    float direction_y = dy / length;
    float origin_x = unit->x;
    float origin_y = unit->y;

    for (float attempted = distance; attempted >= 0.0f; attempted -= 0.25f) {
        float candidate_x = origin_x + direction_x * attempted;
        float candidate_y = origin_y + direction_y * attempted;
        if (!can_place_unit_at(game, unit, candidate_x, candidate_y, ignore_unit_id)) {
            continue;
        }

        unit->x = candidate_x;
        unit->y = candidate_y;
        return attempted;
    }

    return 0.0f;
}

static bool find_legal_position_along_heading(const game_t *game, const unit_t *unit, float angle_degrees, float requested_distance, float *out_x, float *out_y, float *out_distance) {
    if (game == NULL || unit == NULL || out_x == NULL || out_y == NULL || out_distance == NULL) {
        return false;
    }

    float radians = normalize_angle(angle_degrees) * ((float)M_PI / 180.0f);
    for (float distance = requested_distance; distance >= 0.0f; distance -= 0.25f) {
        float candidate_x = unit->x + cosf(radians) * distance;
        float candidate_y = unit->y + sinf(radians) * distance;
        if (!can_place_unit_at(game, unit, candidate_x, candidate_y, -1)) {
            continue;
        }

        *out_x = candidate_x;
        *out_y = candidate_y;
        *out_distance = distance;
        return true;
    }

    *out_x = unit->x;
    *out_y = unit->y;
    *out_distance = 0.0f;
    return false;
}

static bool find_leap_aside_position(const game_t *game, const unit_t *unit, const unit_t *blocker, float preferred_angle_degrees, float *out_x, float *out_y) {
    static const float angle_offsets[] = {0.0f, 20.0f, -20.0f, 45.0f, -45.0f, 75.0f, -75.0f, 110.0f, -110.0f, 145.0f, -145.0f, 180.0f};
    if (game == NULL || unit == NULL || blocker == NULL || out_x == NULL || out_y == NULL) {
        return false;
    }

    float minimum_radius = blocker->footprint_radius + unit->footprint_radius + 0.25f;
    for (float radius = minimum_radius; radius <= minimum_radius + 8.0f; radius += 0.25f) {
        for (int index = 0; index < (int)(sizeof(angle_offsets) / sizeof(angle_offsets[0])); index += 1) {
            float angle = normalize_angle(preferred_angle_degrees + angle_offsets[index]) * ((float)M_PI / 180.0f);
            float candidate_x = blocker->x + cosf(angle) * radius;
            float candidate_y = blocker->y + sinf(angle) * radius;
            if (te_distance(candidate_x, candidate_y, blocker->x, blocker->y) - unit->footprint_radius - blocker->footprint_radius < 0.0f) {
                continue;
            }
            if (!can_place_unit_at(game, unit, candidate_x, candidate_y, blocker->id)) {
                continue;
            }

            *out_x = candidate_x;
            *out_y = candidate_y;
            return true;
        }
    }

    return false;
}

static void resolve_wreck_overlap_displacement(game_t *game, unit_t *wreck, float previous_x, float previous_y) {
    if (game == NULL || wreck == NULL) {
        return;
    }

    float wreck_heading = angle_to(previous_x, previous_y, wreck->x, wreck->y);
    for (int index = 0; index < game->unit_count; index += 1) {
        unit_t *unit = &game->units[index];
        if (unit->destroyed || unit->id == wreck->id || unit_is_embarked(unit)) {
            continue;
        }

        float separation = te_distance(unit->x, unit->y, wreck->x, wreck->y) - unit->footprint_radius - wreck->footprint_radius;
        if (separation >= 0.0f) {
            continue;
        }

        float preferred_angle = angle_to(wreck->x, wreck->y, unit->x, unit->y);
        if (fabsf(unit->x - wreck->x) < 0.01f && fabsf(unit->y - wreck->y) < 0.01f) {
            preferred_angle = normalize_angle(wreck_heading + 180.0f);
        }

        float leap_x = unit->x;
        float leap_y = unit->y;
        if (!find_leap_aside_position(game, unit, wreck, preferred_angle, &leap_x, &leap_y)) {
            te_log(game, "%s cannot find room to leap aside from %s's slewing wreck in the current token model.", unit->name, wreck->name);
            continue;
        }

        unit->x = leap_x;
        unit->y = leap_y;
        te_log(game, "%s leaps aside from %s's slewing wreck.", unit->name, wreck->name);
    }
}

static bool unit_can_move_now(const game_t *game, const unit_t *unit) {
    if (unit->destroyed || unit->owner != game->active_player || game->phase != TE_PHASE_MOVEMENT) {
        return false;
    }
    if (unit->falling_back || unit->locked_in_assault || unit->pinned_until_turn == game->turn_number || unit_is_embarked(unit)) {
        return false;
    }
    if (unit->movement_action_used_this_turn) {
        return false;
    }
    if (unit_uses_vehicle_rules(unit) && (unit->crew_stunned || unit->immobilized)) {
        return false;
    }
    return true;
}

static void resolve_stunned_recon_coast(game_t *game, unit_t *unit) {
    if (game == NULL || unit == NULL || unit->destroyed || !unit->recon || !unit->crew_stunned) {
        return;
    }

    int requested_distance = roll_d6(game);
    float coast_angle = roll_random_direction_degrees(game);
    float destination_x = unit->x;
    float destination_y = unit->y;
    float actual_distance = 0.0f;
    find_legal_position_along_heading(game, unit, coast_angle, (float)requested_distance, &destination_x, &destination_y, &actual_distance);

    bool touches_impassable = path_touches_terrain(game, unit->x, unit->y, destination_x, destination_y, TE_TERRAIN_IMPASSABLE);
    bool touches_difficult = path_touches_terrain(game, unit->x, unit->y, destination_x, destination_y, TE_TERRAIN_DIFFICULT);
    if (actual_distance > 0.01f && (touches_difficult || touches_impassable)) {
        int terrain_roll = roll_d6(game);
        if (terrain_roll == 1) {
            destroy_unit(game, unit, "its stunned crew sent it into an obstacle");
            return;
        }
        te_log(game, "%s keeps control through rough ground on a %d while coasting with stunned crew.", unit->name, terrain_roll);
    }

    if (actual_distance > 0.01f) {
        unit->x = destination_x;
        unit->y = destination_y;
        unit->moved_this_turn = true;
        unit->movement_action_used_this_turn = true;
        unit->moved_distance = actual_distance;
        if (unit_is_transport(unit)) {
            sync_embarked_unit_position(game, unit);
        }
        te_log(game, "%s coasts %.1f\" at %.0f° due to stunned crew and stays facing %.0f°.", unit->name, actual_distance, coast_angle, unit->facing_degrees);
        if (actual_distance + 0.01f < (float)requested_distance) {
            te_log(game, "%s could not complete the full %d\" coast because of nearby terrain or models.", unit->name, requested_distance);
        }
        return;
    }

    unit->movement_action_used_this_turn = true;
    te_log(game, "%s is crew stunned and has no room to coast this movement phase.", unit->name);
}

static bool unit_can_shoot_now(const game_t *game, const unit_t *unit) {
    if (unit->destroyed || unit->owner != game->active_player || game->phase != TE_PHASE_SHOOTING) {
        return false;
    }
    if (unit->shot_this_turn || unit->falling_back || unit->locked_in_assault || unit->pinned_until_turn == game->turn_number || unit_is_embarked(unit)) {
        return false;
    }
    if (unit_uses_vehicle_rules(unit) && (unit->crew_shaken || unit->crew_stunned)) {
        return false;
    }
    if (unit->smoke_used_this_turn) {
        return false;
    }
    return true;
}

static bool unit_can_assault_now(const game_t *game, const unit_t *unit) {
    if (unit->destroyed || unit->owner != game->active_player || game->phase != TE_PHASE_ASSAULT) {
        return false;
    }
    if (unit->assaulted_this_turn || unit->falling_back || unit->pinned_until_turn == game->turn_number || unit_is_embarked(unit)) {
        return false;
    }
    if (unit->kind == TE_UNIT_VEHICLE) {
        return false;
    }
    if (unit_is_crew_stunned_assault_gun(unit) && !unit->locked_in_assault) {
        return false;
    }
    return true;
}

static int vehicle_max_weapons(const unit_t *unit) {
    if (unit->kind == TE_UNIT_ASSAULT_GUN) {
        return unit->moved_distance > 0.0f ? 2 : unit->weapon_count;
    }

    if (unit->fast) {
        if (unit->moved_distance <= 6.0f) {
            return unit->weapon_count;
        }
        if (unit->moved_distance <= 12.0f) {
            return 1;
        }
        return 0;
    }

    if (unit->moved_distance <= 0.01f) {
        return unit->weapon_count;
    }
    if (unit->moved_distance <= 6.0f) {
        return 1;
    }
    return 0;
}

static void init_shooting_phase(game_t *game) {
    for (int index = 0; index < game->unit_count; index += 1) {
        unit_t *unit = &game->units[index];
        unit->shooting_phase_strength = unit->models;
        unit->casualties_this_shooting_phase = 0;
        unit->morale_checked_this_phase = false;
    }
}

static void finish_turn(game_t *game, player_t player) {
    for (int index = 0; index < game->unit_count; index += 1) {
        unit_t *unit = &game->units[index];
        if (unit->owner != player) {
            continue;
        }
        if (unit->crew_shaken && unit->crew_shaken_until_turn == game->turn_number) {
            unit->crew_shaken = false;
            unit->crew_shaken_until_turn = 0;
        }
        if (unit->crew_stunned && unit->crew_stunned_until_turn == game->turn_number) {
            unit->crew_stunned = false;
            unit->crew_stunned_until_turn = 0;
        }
        if (unit->pinned_until_turn == game->turn_number) {
            unit->pinned_until_turn = 0;
            te_log(game, "%s is no longer pinned.", unit->name);
        }
    }
}

static void begin_turn(game_t *game) {
    for (int index = 0; index < game->unit_count; index += 1) {
        unit_t *unit = &game->units[index];
        if (unit->owner != game->active_player || unit->destroyed) {
            continue;
        }

        unit->moved_this_turn = false;
        unit->movement_action_used_this_turn = false;
        unit->shot_this_turn = false;
        unit->assaulted_this_turn = false;
        unit->moved_distance = 0.0f;
        unit->smoke_used_this_turn = false;
        unit->fired_stationary_rapid_or_heavy = false;
        unit->embarked_this_turn = false;

        if (unit->pinned_until_turn == game->turn_number) {
            te_log(game, "%s is pinned and cannot move, shoot, or assault this turn.", unit->name);
        }

        if (unit->smoke_active) {
            unit->smoke_active = false;
        }

        if (unit->recon && unit->crew_stunned) {
            resolve_stunned_recon_coast(game, unit);
            if (unit->destroyed) {
                continue;
            }
        }

        if (!unit->falling_back) {
            continue;
        }

        bool can_attempt_regroup = unit->models * 2 >= unit->starting_models && !enemy_within_distance(game, unit, 6.0f);
        if (!can_attempt_regroup) {
            int fallback_distance = roll_2d6(game);
            resolve_fall_back(game, unit, fallback_distance);
            unit->moved_this_turn = true;
            unit->movement_action_used_this_turn = true;
            unit->shot_this_turn = true;
            unit->assaulted_this_turn = true;
            continue;
        }

        int regroup_roll = roll_2d6(game);
        if (regroup_roll <= unit->leadership) {
            unit->falling_back = false;
            te_log(game, "%s regroups on a %d against Leadership %d.", unit->name, regroup_roll, unit->leadership);
        } else {
            int fallback_distance = roll_2d6(game);
            te_log(game, "%s fails to regroup on a %d against Leadership %d.", unit->name, regroup_roll, unit->leadership);
            resolve_fall_back(game, unit, fallback_distance);
            unit->moved_this_turn = true;
            unit->movement_action_used_this_turn = true;
            unit->shot_this_turn = true;
            unit->assaulted_this_turn = true;
        }
    }

    te_log(game, "Turn %d begins for %s in the %s phase.", game->turn_number, player_name(game->active_player), phase_name(game->phase));
}

static void te_apply_shooting_morale(game_t *game, unit_t *unit) {
    if (unit->destroyed || unit->morale_checked_this_phase || unit->shooting_phase_strength <= 0) {
        return;
    }

    int threshold = (unit->shooting_phase_strength + 3) / 4;
    if (unit->casualties_this_shooting_phase < threshold) {
        return;
    }

    unit->morale_checked_this_phase = true;
    int morale_roll = roll_2d6(game);
    if (morale_roll <= unit->leadership) {
        te_log(game, "%s holds after losing %d models; morale roll %d vs Leadership %d.", unit->name, unit->casualties_this_shooting_phase, morale_roll, unit->leadership);
        return;
    }

    te_log(game, "%s breaks after enemy fire; morale roll %d vs Leadership %d.", unit->name, morale_roll, unit->leadership);
    resolve_fall_back(game, unit, roll_2d6(game));
}

static void apply_pinning(game_t *game, unit_t *unit, int modifier, const char *source_name) {
    if (unit->destroyed || unit_uses_vehicle_rules(unit) || unit->falling_back) {
        return;
    }

    int target_number = unit->leadership + modifier;
    if (target_number < 2) {
        target_number = 2;
    }

    int morale_roll = roll_2d6(game);
    if (morale_roll <= target_number) {
        te_log(game, "%s resists pinning from %s on %d against Leadership %d.", unit->name, source_name, morale_roll, target_number);
        return;
    }

    pin_unit_until_next_turn(game, unit);
    te_log(game, "%s is pinned by %s on %d against Leadership %d and will be unable to act on its next turn.", unit->name, source_name, morale_roll, target_number);
}

static int apply_infantry_damage(game_t *game, unit_t *unit, int wounds, int damage_strength, const char *source_name, bool count_for_shooting_phase, int *out_models_lost) {
    if (out_models_lost != NULL) {
        *out_models_lost = 0;
    }
    if (wounds <= 0 || unit->destroyed) {
        return 0;
    }

    normalize_unit_wounds(unit);

    if (unit_has_profile_groups(unit)) {
        int indices[TE_MAX_PROFILE_GROUPS];
        int index_count = 0;
        order_profile_group_indices_for_casualties(unit, indices, &index_count);

        int remaining = wounds;
        int total_applied = 0;
        int total_models_lost = 0;
        for (int order = 0; order < index_count && remaining > 0; order += 1) {
            profile_group_t *group = &unit->profile_groups[indices[order]];
            bool instant_death = damage_strength > 0 && group->wounds_per_model > 1 && damage_strength >= group->toughness * 2;
            int group_models_lost = 0;
            int applied = apply_profile_group_damage(game, unit, group, remaining, instant_death, source_name, &group_models_lost);
            remaining -= applied;
            total_applied += applied;
            total_models_lost += group_models_lost;
        }

        sync_unit_from_profile_groups(unit);
        if (count_for_shooting_phase) {
            unit->casualties_this_shooting_phase += total_models_lost;
        }
        if (out_models_lost != NULL) {
            *out_models_lost = total_models_lost;
        }
        if (unit->models <= 0) {
            destroy_unit(game, unit, "the unit was wiped out");
        }
        return total_applied;
    }

    int instant_death = damage_strength > 0 && unit->wounds_per_model > 1 && damage_strength >= unit->toughness * 2;
    int applied = wounds;
    int total_wounds = instant_death ? unit->models : te_total_wounds_remaining(unit);
    if (applied > total_wounds) {
        applied = total_wounds;
    }

    int models_lost = 0;
    if (instant_death) {
        models_lost = applied;
        unit->models -= applied;
        if (unit->models <= 0) {
            unit->models = 0;
            unit->lead_model_wounds = 0;
        }
    } else {
        int remaining = applied;
        while (remaining > 0 && unit->models > 0) {
            if (remaining < unit->lead_model_wounds) {
                unit->lead_model_wounds -= remaining;
                remaining = 0;
                break;
            }

            remaining -= unit->lead_model_wounds;
            unit->models -= 1;
            models_lost += 1;
            if (unit->models > 0) {
                unit->lead_model_wounds = unit->wounds_per_model;
            } else {
                unit->lead_model_wounds = 0;
            }
        }
    }

    if (count_for_shooting_phase) {
        unit->casualties_this_shooting_phase += models_lost;
    }
    if (out_models_lost != NULL) {
        *out_models_lost = models_lost;
    }

    if (instant_death) {
        te_log(game, "%s suffers %d instant-kill wound%s from %s, losing %d model%s.", unit->name, applied, applied == 1 ? "" : "s", source_name, models_lost, models_lost == 1 ? "" : "s");
    } else if (unit->wounds_per_model <= 1) {
        te_log(game, "%s loses %d model%s to %s.", unit->name, models_lost, models_lost == 1 ? "" : "s", source_name);
    } else if (models_lost <= 0) {
        te_log(game, "%s suffers %d unsaved wound%s from %s; the lead model is reduced to %d/%d wounds.", unit->name, applied, applied == 1 ? "" : "s", source_name, unit->lead_model_wounds, unit->wounds_per_model);
    } else if (unit->models > 0 && unit->lead_model_wounds < unit->wounds_per_model) {
        te_log(game, "%s suffers %d unsaved wound%s from %s, losing %d model%s and leaving the lead model on %d/%d wounds.", unit->name, applied, applied == 1 ? "" : "s", source_name, models_lost, models_lost == 1 ? "" : "s", unit->lead_model_wounds, unit->wounds_per_model);
    } else {
        te_log(game, "%s suffers %d unsaved wound%s from %s, losing %d model%s.", unit->name, applied, applied == 1 ? "" : "s", source_name, models_lost, models_lost == 1 ? "" : "s");
    }

    if (unit->models <= 0) {
        destroy_unit(game, unit, "the unit was wiped out");
    }
    return applied;
}

static int choose_armour_save(const game_t *game, const unit_t *unit, int weapon_ap) {
    int armour_save = 0;
    if (unit->save > 0 && (weapon_ap <= 0 || weapon_ap > unit->save)) {
        armour_save = unit->save;
    }

    int cover_save = cover_save_for_unit(game, unit);
    if (cover_save > 0 && (armour_save == 0 || cover_save < armour_save)) {
        armour_save = cover_save;
    }

    return armour_save;
}

static int choose_armour_save_with_weapon(const game_t *game, const unit_t *unit, const weapon_profile_t *weapon) {
    int armour_save = 0;
    if (unit->save > 0 && (weapon->ap <= 0 || weapon->ap > unit->save)) {
        armour_save = unit->save;
    }

    if (!weapon->ignores_cover) {
        int cover_save = cover_save_for_unit(game, unit);
        if (cover_save > 0 && (armour_save == 0 || cover_save < armour_save)) {
            armour_save = cover_save;
        }
    }

    return armour_save;
}

static bool roll_to_hit_with_linked(game_t *game, int needed_to_hit, bool linked) {
    if (roll_d6(game) >= needed_to_hit) {
        return true;
    }
    if (!linked) {
        return false;
    }
    return roll_d6(game) >= needed_to_hit;
}

static bool scatter_marker(game_t *game, float origin_x, float origin_y, float *marker_x, float *marker_y, int *scatter_distance) {
    if (roll_d6(game) <= 2) {
        *marker_x = origin_x;
        *marker_y = origin_y;
        if (scatter_distance != NULL) {
            *scatter_distance = 0;
        }
        return true;
    }

    int distance = roll_d6(game);
    float angle = (float)(next_random(game) % 360u) * ((float)M_PI / 180.0f);
    *marker_x = origin_x + cosf(angle) * (float)distance;
    *marker_y = origin_y + sinf(angle) * (float)distance;
    if (scatter_distance != NULL) {
        *scatter_distance = distance;
    }
    return false;
}

static void slew_vehicle_wreck(game_t *game, unit_t *vehicle, const char *source_name) {
    if (game == NULL || vehicle == NULL || vehicle->destroyed) {
        return;
    }

    float previous_x = vehicle->x;
    float previous_y = vehicle->y;
    float wreck_x = vehicle->x;
    float wreck_y = vehicle->y;
    int scatter_distance = 0;
    bool direct_hit = scatter_marker(game, vehicle->x, vehicle->y, &wreck_x, &wreck_y, &scatter_distance);
    if (direct_hit || scatter_distance <= 0) {
        te_log(game, "%s flips in place from %s.", vehicle->name, source_name);
        return;
    }

    vehicle->x = fminf(fmaxf(wreck_x, vehicle->footprint_radius), TE_BOARD_WIDTH - vehicle->footprint_radius);
    vehicle->y = fminf(fmaxf(wreck_y, vehicle->footprint_radius), TE_BOARD_HEIGHT - vehicle->footprint_radius);
    te_log(game, "%s's wreck slews %d\" from %s.", vehicle->name, scatter_distance, source_name);
    resolve_wreck_overlap_displacement(game, vehicle, previous_x, previous_y);
}

static int estimate_template_hits(game_t *game, const unit_t *target, float marker_x, float marker_y, int blast_diameter) {
    float blast_radius = (float)blast_diameter * 0.5f;
    float center_distance = te_distance(marker_x, marker_y, target->x, target->y);
    float overlap_limit = blast_radius + target->footprint_radius;
    if (center_distance >= overlap_limit) {
        return 0;
    }

    float coverage = 1.0f - (center_distance / overlap_limit);
    float density = (blast_radius * blast_radius) / (blast_radius * blast_radius + target->footprint_radius * target->footprint_radius);
    int estimated_hits = (int)lroundf((float)target->models * density * coverage);
    if (estimated_hits <= 0) {
        estimated_hits = roll_d6(game) >= 4 ? 1 : 0;
    }
    if (estimated_hits > target->models) {
        estimated_hits = target->models;
    }
    return estimated_hits;
}

static int estimate_flame_hits(game_t *game, const unit_t *attacker, const unit_t *target, int template_length) {
    float edge_distance = te_distance(attacker->x, attacker->y, target->x, target->y) - attacker->footprint_radius - target->footprint_radius;
    if (edge_distance > (float)template_length) {
        return 0;
    }

    if (edge_distance < 0.0f) {
        edge_distance = 0.0f;
    }

    float coverage = 1.0f - (edge_distance / (float)template_length);
    float density = fminf(0.72f, 0.34f + target->footprint_radius * 0.12f);
    int estimated_hits = (int)lroundf((float)target->models * density * coverage);
    if (estimated_hits <= 0) {
        estimated_hits = roll_d6(game) >= 4 ? 1 : 0;
    }
    if (estimated_hits > target->models) {
        estimated_hits = target->models;
    }
    return estimated_hits;
}

static int template_hits_vehicle(const unit_t *target, float marker_x, float marker_y, int blast_diameter) {
    float blast_radius = (float)blast_diameter * 0.5f;
    float center_distance = te_distance(marker_x, marker_y, target->x, target->y);
    if (center_distance > blast_radius + target->footprint_radius) {
        return 0;
    }
    return target->open_topped ? 2 : 1;
}

static int flame_hits_vehicle(const unit_t *attacker, const unit_t *target, int template_length) {
    float edge_distance = te_distance(attacker->x, attacker->y, target->x, target->y) - attacker->footprint_radius - target->footprint_radius;
    if (edge_distance > (float)template_length) {
        return 0;
    }
    return target->open_topped ? 2 : 1;
}

static void apply_vehicle_blast_radius(game_t *game, const unit_t *source, int radius, const char *reason) {
    for (int index = 0; index < game->unit_count; index += 1) {
        unit_t *unit = &game->units[index];
        if (unit->destroyed || unit_uses_vehicle_rules(unit) || unit->id == source->id || unit_is_embarked(unit)) {
            continue;
        }

        float edge_distance = te_distance(source->x, source->y, unit->x, unit->y) - source->footprint_radius - unit->footprint_radius;
        if (edge_distance > (float)radius) {
            continue;
        }

        int casualties = 0;
        for (int model = 0; model < unit->models; model += 1) {
            if (roll_d6(game) < 4) {
                continue;
            }
            int save = choose_armour_save(game, unit, 0);
            if (save > 0 && roll_save(game, save)) {
                continue;
            }
            casualties += 1;
        }

        if (casualties > 0) {
            apply_infantry_damage(game, unit, casualties, 0, reason, game->phase == TE_PHASE_SHOOTING, NULL);
        }
    }
}

static int vehicle_armour_for_arc(const unit_t *vehicle, float attacker_x, float attacker_y) {
    float angle_from_vehicle = angle_to(vehicle->x, vehicle->y, attacker_x, attacker_y);
    float difference = smallest_angle_between(vehicle->facing_degrees, angle_from_vehicle);

    if (difference <= 45.0f) {
        return vehicle->front_armour;
    }
    if (difference >= 135.0f) {
        return vehicle->rear_armour;
    }
    return vehicle->side_armour;
}

static void record_weapon_fire_angle(const unit_t *attacker, const unit_t *target, weapon_slot_t *slot) {
    if (attacker == NULL || target == NULL || slot == NULL) {
        return;
    }

    slot->has_last_fire_angle = true;
    slot->last_fire_angle_degrees = angle_to(attacker->x, attacker->y, target->x, target->y);
}

static bool weapon_mount_can_jam(const weapon_profile_t *weapon) {
    if (weapon == NULL) {
        return false;
    }

    return weapon->mount == TE_WEAPON_MOUNT_TURRET_INTERNAL || weapon->mount == TE_WEAPON_MOUNT_SPONSON_INTERNAL;
}

static int jam_vehicle_traverse_weapons(game_t *game, unit_t *vehicle) {
    if (game == NULL || vehicle == NULL) {
        return 0;
    }

    int jammed_weapons = 0;
    for (int index = 0; index < vehicle->weapon_count; index += 1) {
        weapon_slot_t *slot = &vehicle->weapons[index];
        if (slot->destroyed || !weapon_mount_can_jam(&slot->profile) || slot->jammed_in_place) {
            continue;
        }

        slot->jammed_in_place = true;
        slot->jammed_fire_angle_degrees = slot->has_last_fire_angle ? slot->last_fire_angle_degrees : vehicle->facing_degrees;
        jammed_weapons += 1;
        te_log(game, "%s's %s jams in place at %.0f° after a second immobilized result.", vehicle->name, slot->profile.name, slot->jammed_fire_angle_degrees);
    }

    if (jammed_weapons == 0) {
        te_log(game, "%s suffers another immobilized result, but has no turret or sponson weapons left to jam.", vehicle->name);
    }

    return jammed_weapons;
}

static void apply_immobilized_result(game_t *game, unit_t *vehicle, const char *first_result_message) {
    if (game == NULL || vehicle == NULL) {
        return;
    }

    if (vehicle->immobilized) {
        jam_vehicle_traverse_weapons(game, vehicle);
        return;
    }

    vehicle->immobilized = true;
    te_log(game, "%s %s", vehicle->name, first_result_message);
}

static void apply_ordnance_vehicle_damage(game_t *game, const unit_t *attacker, unit_t *vehicle) {
    int damage_roll = roll_d6(game);
    if (vehicle->open_topped) {
        damage_roll += 1;
    }
    if (damage_roll > 6) {
        damage_roll = 6;
    }

    switch (damage_roll) {
        case 1:
            set_unit_crew_stunned_until_next_turn(game, vehicle);
            te_log(game, "%s suffers Crew Stunned from ordnance.", vehicle->name);
            break;
        case 2:
            apply_immobilized_result(game, vehicle, "is immobilized by the ordnance hit.");
            break;
        case 3: {
            handle_weapon_destroy_result(game, attacker, vehicle, "an ordnance hit ripped away its remaining systems");
            break;
        }
        case 4:
            slew_vehicle_wreck(game, vehicle, "the ordnance impact");
            destroy_unit(game, vehicle, "an ordnance hit wrecked it");
            break;
        case 5: {
            int radius = roll_d6(game);
            te_log(game, "%s detonates in a %d\" ordnance fireball.", vehicle->name, radius);
            apply_vehicle_blast_radius(game, vehicle, radius, "ordnance detonation");
            destroy_unit(game, vehicle, "its fuel and ammunition detonated");
            break;
        }
        case 6:
            te_log(game, "%s is annihilated by the ordnance strike, spraying shrapnel 6\".", vehicle->name);
            apply_vehicle_blast_radius(game, vehicle, 6, "ordnance annihilation");
            destroy_unit_with_passenger_outcome(game, vehicle, "it was blown to pieces by ordnance", true);
            break;
        default:
            break;
    }
}

static void apply_vehicle_damage(game_t *game, const unit_t *attacker, unit_t *vehicle, bool glancing_hit) {
    int damage_roll = roll_d6(game);
    if (vehicle->open_topped) {
        damage_roll += 1;
    }
    if (damage_roll > 6) {
        damage_roll = 6;
    }

    if (glancing_hit) {
        switch (damage_roll) {
            case 1:
                set_unit_crew_shaken_until_next_turn(game, vehicle);
                te_log(game, "%s suffers Crew Shaken.", vehicle->name);
                break;
            case 2:
                set_unit_crew_stunned_until_next_turn(game, vehicle);
                te_log(game, "%s suffers Crew Stunned.", vehicle->name);
                break;
            case 3:
                apply_immobilized_result(game, vehicle, "is immobilized.");
                break;
            case 4: {
                handle_weapon_destroy_result(game, attacker, vehicle, "a second weapon-destroyed result wrecked it");
                break;
            }
            case 5:
            case 6:
                destroy_unit(game, vehicle, "a glancing hit wrecked it");
                break;
            default:
                break;
        }
        return;
    }

    switch (damage_roll) {
        case 1:
            set_unit_crew_stunned_until_next_turn(game, vehicle);
            te_log(game, "%s suffers Crew Stunned.", vehicle->name);
            break;
        case 2:
            apply_immobilized_result(game, vehicle, "is immobilized.");
            break;
        case 3: {
            handle_weapon_destroy_result(game, attacker, vehicle, "a penetrating hit wrecked its systems");
            break;
        }
        case 4:
            destroy_unit(game, vehicle, "a penetrating hit wrecked it");
            break;
        case 5:
            slew_vehicle_wreck(game, vehicle, "the internal explosion");
            destroy_unit(game, vehicle, "an internal explosion destroyed it");
            break;
        case 6: {
            int radius = roll_d6(game);
            te_log(game, "%s detonates in a %d\" blast.", vehicle->name, radius);
            apply_vehicle_blast_radius(game, vehicle, radius, "vehicle detonation");
            destroy_unit(game, vehicle, "its fuel and ammunition detonated");
            break;
        }
        default:
            break;
    }
}

static void log_profile_group_allocation(game_t *game, const unit_t *target, const int *allocated_hits) {
    if (game == NULL || target == NULL || allocated_hits == NULL) {
        return;
    }

    char buffer[TE_LOG_LINE_LENGTH];
    int written = snprintf(buffer, sizeof(buffer), "%s allocates mixed-profile hits:", target->name);
    for (int index = 0; index < target->profile_group_count && written < (int)sizeof(buffer); index += 1) {
        if (allocated_hits[index] <= 0) {
            continue;
        }
        written += snprintf(buffer + written, sizeof(buffer) - (size_t)written, " %d to %s;", allocated_hits[index], target->profile_groups[index].name);
    }
    te_log(game, "%s", buffer);
}

static int resolve_allocated_mixed_infantry_hits(game_t *game, const char *attacker_name, unit_t *target, const weapon_profile_t *weapon, const int *allocated_hits) {
    if (game == NULL || target == NULL || weapon == NULL || allocated_hits == NULL) {
        return 0;
    }

    log_profile_group_allocation(game, target, allocated_hits);

    int hits = 0;
    int wounds = 0;
    int unsaved_wounds = 0;
    int models_lost = 0;

    for (int index = 0; index < target->profile_group_count; index += 1) {
        profile_group_t *group = &target->profile_groups[index];
        if (allocated_hits[index] <= 0 || group->models <= 0) {
            continue;
        }

        hits += allocated_hits[index];
        bool instant_death = weapon->strength >= group->toughness * 2 && group->wounds_per_model > 1;
        for (int hit = 0; hit < allocated_hits[index]; hit += 1) {
            int needed_to_wound = required_to_wound(weapon->strength, group->toughness);
            if (needed_to_wound > 6) {
                continue;
            }
            if (roll_d6(game) < needed_to_wound) {
                continue;
            }

            wounds += 1;
            int save = choose_profile_group_save_with_weapon(game, target, group, weapon);
            if (save > 0 && roll_save(game, save)) {
                continue;
            }

            int lost_from_group = 0;
            unsaved_wounds += 1;
            apply_profile_group_damage(game, target, group, 1, instant_death, weapon->name, &lost_from_group);
            models_lost += lost_from_group;
        }
    }

    sync_unit_from_profile_groups(target);
    target->casualties_this_shooting_phase += models_lost;
    te_log(game, "%s's %s converts %d allocated hit%s into %d wound%s and %d unsaved on %s.", attacker_name, weapon->name, hits, hits == 1 ? "" : "s", wounds, wounds == 1 ? "" : "s", unsaved_wounds, target->name);
    if (target->models <= 0) {
        destroy_unit(game, target, "the unit was wiped out");
    }
    return unsaved_wounds;
}

static int resolve_allocated_mixed_melee_hits(game_t *game, const char *source_name, int strength, unit_t *defender, const int *allocated_hits) {
    if (game == NULL || defender == NULL || allocated_hits == NULL) {
        return 0;
    }

    log_profile_group_allocation(game, defender, allocated_hits);

    int hits = 0;
    int wounds = 0;
    int unsaved_wounds = 0;

    for (int index = 0; index < defender->profile_group_count; index += 1) {
        profile_group_t *group = &defender->profile_groups[index];
        if (allocated_hits[index] <= 0 || group->models <= 0) {
            continue;
        }

        hits += allocated_hits[index];
        bool instant_death = strength >= group->toughness * 2 && group->wounds_per_model > 1;
        int needed_to_wound = required_to_wound(strength, group->toughness);
        if (needed_to_wound > 6) {
            continue;
        }

        for (int hit = 0; hit < allocated_hits[index]; hit += 1) {
            if (roll_d6(game) < needed_to_wound) {
                continue;
            }

            wounds += 1;
            if (group->save > 0 && roll_save(game, group->save)) {
                continue;
            }

            unsaved_wounds += 1;
            apply_profile_group_damage(game, defender, group, 1, instant_death, source_name, NULL);
        }
    }

    sync_unit_from_profile_groups(defender);
    te_log(game, "%s converts %d melee hit%s into %d wound%s and %d unsaved on %s.", source_name, hits, hits == 1 ? "" : "s", wounds, wounds == 1 ? "" : "s", unsaved_wounds, defender->name);
    if (defender->models <= 0) {
        destroy_unit(game, defender, "the unit was wiped out");
    }
    return unsaved_wounds;
}

static void begin_pending_hit_allocation_choice(
    game_t *game,
    pending_hit_allocation_kind_t kind,
    player_t chooser_owner,
    const char *attacker_name,
    const char *source_name,
    unit_t *target,
    int strength,
    bool ignores_cover,
    bool barrage,
    bool ordnance,
    int hits
) {
    if (game == NULL || target == NULL || source_name == NULL || hits <= 0) {
        return;
    }

    clear_pending_hit_allocation_choice(game);
    game->pending_hit_allocation_active = true;
    game->pending_hit_allocation_kind = kind;
    game->pending_hit_allocation_chooser_owner = chooser_owner;
    game->pending_hit_allocation_attacker_name = attacker_name;
    game->pending_hit_allocation_source_name = source_name;
    game->pending_hit_allocation_target_id = target->id;
    game->pending_hit_allocation_barrage = barrage;
    game->pending_hit_allocation_ordnance = ordnance;
    game->pending_hit_allocation_strength = strength;
    game->pending_hit_allocation_ignores_cover = ignores_cover;
    game->pending_hit_allocation_target_models_before = target->models;
    game->pending_hit_allocation_hits_remaining = hits;
    game->pending_hit_allocation_total_hits = hits;
    te_log(game, "%s must allocate %d mixed-profile hit%s on %s from %s's %s.", player_name(chooser_owner), hits, hits == 1 ? "" : "s", target->name, attacker_name != NULL ? attacker_name : "the attacker", source_name);
}

static void begin_pending_shooting_hit_allocation_choice(game_t *game, const unit_t *attacker, unit_t *target, const weapon_profile_t *weapon, int hits) {
    if (game == NULL || attacker == NULL || target == NULL || weapon == NULL) {
        return;
    }

    begin_pending_hit_allocation_choice(
        game,
        TE_PENDING_HIT_ALLOCATION_SHOOTING,
        target->owner,
        attacker->name,
        weapon->name,
        target,
        weapon->strength,
        weapon->ignores_cover,
        weapon->barrage,
        weapon->ordnance,
        hits
    );
}

static void begin_pending_melee_hit_allocation_choice(game_t *game, const char *attacker_name, const char *source_name, unit_t *target, int strength, int hits) {
    begin_pending_hit_allocation_choice(
        game,
        TE_PENDING_HIT_ALLOCATION_MELEE,
        target != NULL ? target->owner : TE_PLAYER_NONE,
        attacker_name,
        source_name,
        target,
        strength,
        true,
        false,
        false,
        hits
    );
}

static void resolve_mixed_infantry_hits(game_t *game, const unit_t *attacker, unit_t *target, const weapon_profile_t *weapon, int hits) {
    if (hits <= 0) {
        return;
    }

    if (live_profile_group_count(target) > 1 && target->preferred_casualty_group_index < 0) {
        begin_pending_shooting_hit_allocation_choice(game, attacker, target, weapon, hits);
        return;
    }

    int allocated_hits[TE_MAX_PROFILE_GROUPS];
    memset(allocated_hits, 0, sizeof(allocated_hits));
    allocate_hits_to_profile_groups(target, hits, allocated_hits);
    (void)resolve_allocated_mixed_infantry_hits(game, attacker->name, target, weapon, allocated_hits);
}

static void resolve_weapon_against_infantry(game_t *game, const unit_t *attacker, unit_t *target, const weapon_profile_t *weapon, int shots) {
    int hits = 0;
    int wounds = 0;
    int unsaved_wounds = 0;

    if (weapon->flame) {
        hits = estimate_flame_hits(game, attacker, target, weapon->range);
        if (hits <= 0) {
            te_log(game, "%s's %s does not quite reach %s.", attacker->name, weapon->name, target->name);
            return;
        }

        te_log(game, "%s sweeps %s over %s: %d template hit%s, cover ignored.", attacker->name, weapon->name, target->name, hits, hits == 1 ? "" : "s");
        if (unit_has_mixed_profiles(target)) {
            resolve_mixed_infantry_hits(game, attacker, target, weapon, hits);
            return;
        }
        for (int hit = 0; hit < hits; hit += 1) {
            int needed_to_wound = required_to_wound(weapon->strength, target->toughness);
            if (needed_to_wound > 6) {
                continue;
            }
            if (roll_d6(game) < needed_to_wound) {
                continue;
            }
            wounds += 1;

            int save = choose_armour_save_with_weapon(game, target, weapon);
            if (save > 0 && roll_save(game, save)) {
                continue;
            }
            unsaved_wounds += 1;
        }

        te_log(game, "%s's %s converts %d hit%s into %d wound%s and %d unsaved.", attacker->name, weapon->name, hits, hits == 1 ? "" : "s", wounds, wounds == 1 ? "" : "s", unsaved_wounds);
        apply_infantry_damage(game, target, unsaved_wounds, weapon->strength, weapon->name, true, NULL);
        return;
    }

    if (weapon->blast_diameter > 0) {
        float marker_x = target->x;
        float marker_y = target->y;
        bool direct_hit = true;
        int scatter_distance = 0;

        if (weapon->ordnance || weapon->barrage) {
            direct_hit = scatter_marker(game, target->x, target->y, &marker_x, &marker_y, &scatter_distance);
        } else {
            int needed_to_hit = required_to_hit_ballistic(attacker->ballistic_skill);
            if (!roll_to_hit_with_linked(game, needed_to_hit, weapon->linked)) {
                te_log(game, "%s's %s misses cleanly.", attacker->name, weapon->name);
                return;
            }
        }

        hits = estimate_template_hits(game, target, marker_x, marker_y, weapon->blast_diameter);
        if (hits <= 0) {
            te_log(game, "%s's %s scatters clear of %s.", attacker->name, weapon->name, target->name);
            return;
        }

        if (weapon->ordnance || weapon->barrage) {
            te_log(game, "%s fires %s: %s, %d template hit%s on %s.", attacker->name, weapon->name, direct_hit ? "direct hit" : "scatter", hits, hits == 1 ? "" : "s", target->name);
        } else {
            te_log(game, "%s fires %s: %d template hit%s on %s.", attacker->name, weapon->name, hits, hits == 1 ? "" : "s", target->name);
        }

        if (unit_has_mixed_profiles(target)) {
            resolve_mixed_infantry_hits(game, attacker, target, weapon, hits);
            return;
        }
        for (int hit = 0; hit < hits; hit += 1) {
            int needed_to_wound = required_to_wound(weapon->strength, target->toughness);
            if (needed_to_wound > 6) {
                continue;
            }
            if (roll_d6(game) < needed_to_wound) {
                continue;
            }
            wounds += 1;

            int save = choose_armour_save_with_weapon(game, target, weapon);
            if (save > 0 && roll_save(game, save)) {
                continue;
            }
            unsaved_wounds += 1;
        }

        te_log(game, "%s's %s converts %d hit%s into %d wound%s and %d unsaved.", attacker->name, weapon->name, hits, hits == 1 ? "" : "s", wounds, wounds == 1 ? "" : "s", unsaved_wounds);
        apply_infantry_damage(game, target, unsaved_wounds, weapon->strength, weapon->name, true, NULL);
        return;
    }

    int needed_to_hit = required_to_hit_ballistic(attacker->ballistic_skill);
    for (int shot = 0; shot < shots; shot += 1) {
        if (!roll_to_hit_with_linked(game, needed_to_hit, weapon->linked)) {
            continue;
        }
        hits += 1;
    }

    if (unit_has_mixed_profiles(target)) {
        resolve_mixed_infantry_hits(game, attacker, target, weapon, hits);
        return;
    }

    for (int hit = 0; hit < hits; hit += 1) {
        int needed_to_wound = required_to_wound(weapon->strength, target->toughness);
        if (needed_to_wound > 6) {
            continue;
        }

        if (roll_d6(game) < needed_to_wound) {
            continue;
        }
        wounds += 1;

        int save = choose_armour_save_with_weapon(game, target, weapon);
        if (save > 0 && roll_save(game, save)) {
            continue;
        }

        unsaved_wounds += 1;
    }

    te_log(game, "%s fires %s: %d shot%s, %d hit%s, %d wound%s, %d unsaved.", attacker->name, weapon->name, shots, shots == 1 ? "" : "s", hits, hits == 1 ? "" : "s", wounds, wounds == 1 ? "" : "s", unsaved_wounds);
    apply_infantry_damage(game, target, unsaved_wounds, weapon->strength, weapon->name, true, NULL);
}

static bool finalize_pending_hit_allocation_choice(game_t *game, bool apply_shooting_morale, int *out_unsaved_wounds) {
    if (out_unsaved_wounds != NULL) {
        *out_unsaved_wounds = 0;
    }
    if (!game_has_pending_hit_allocation_choice(game)) {
        return false;
    }

    unit_t *target = find_unit(game, game->pending_hit_allocation_target_id);
    if (target == NULL || target->destroyed) {
        clear_pending_hit_allocation_choice(game);
        clear_pending_banded_melee_resolution(game);
        clear_pending_one_sided_melee_resolution(game);
        clear_pending_simultaneous_melee_resolution(game);
        clear_pending_vehicle_shot_sequence(game);
        return fail(game, "The mixed-profile target is no longer available.");
    }

    const char *attacker_name = game->pending_hit_allocation_attacker_name != NULL ? game->pending_hit_allocation_attacker_name : "The attacker";
    pending_hit_allocation_kind_t allocation_kind = game->pending_hit_allocation_kind;
    const char *source_name = game->pending_hit_allocation_source_name;
    bool barrage = game->pending_hit_allocation_barrage;
    bool ordnance = game->pending_hit_allocation_ordnance;
    int target_models_before = game->pending_hit_allocation_target_models_before;
    int unsaved_wounds = 0;

    if (allocation_kind == TE_PENDING_HIT_ALLOCATION_MELEE) {
        unsaved_wounds = resolve_allocated_mixed_melee_hits(
            game,
            source_name != NULL ? source_name : attacker_name,
            game->pending_hit_allocation_strength,
            target,
            game->pending_hit_allocation_allocated_hits
        );
    } else {
        weapon_profile_t pending_weapon;
        memset(&pending_weapon, 0, sizeof(pending_weapon));
        pending_weapon.name = source_name;
        pending_weapon.strength = game->pending_hit_allocation_strength;
        pending_weapon.ignores_cover = game->pending_hit_allocation_ignores_cover;
        pending_weapon.barrage = barrage;
        pending_weapon.ordnance = ordnance;
        unsaved_wounds = resolve_allocated_mixed_infantry_hits(game, attacker_name, target, &pending_weapon, game->pending_hit_allocation_allocated_hits);
    }

    clear_pending_hit_allocation_choice(game);
    if (allocation_kind == TE_PENDING_HIT_ALLOCATION_SHOOTING && !target->destroyed && target->models < target_models_before && barrage) {
        apply_pinning(game, target, ordnance ? -1 : 0, source_name);
    }
    if (apply_shooting_morale && !target->destroyed && allocation_kind == TE_PENDING_HIT_ALLOCATION_SHOOTING) {
        te_apply_shooting_morale(game, target);
    }
    if (out_unsaved_wounds != NULL) {
        *out_unsaved_wounds = unsaved_wounds;
    }
    return true;
}

static void resolve_weapon_against_vehicle(game_t *game, const unit_t *attacker, unit_t *target, const weapon_profile_t *weapon, int shots) {
    int armour_value = vehicle_armour_for_arc(target, attacker->x, attacker->y);
    bool protective_glancing_only = target->smoke_active || hull_down_for_unit(game, target) || (target->recon && target->moved_distance > 6.0f);

    if (weapon->flame) {
        int hits = flame_hits_vehicle(attacker, target, weapon->range);
        if (hits <= 0) {
            te_log(game, "%s's %s does not reach %s.", attacker->name, weapon->name, target->name);
            return;
        }

        te_log(game, "%s bathes %s in %s: %d template hit%s.", attacker->name, target->name, weapon->name, hits, hits == 1 ? "" : "s");
        for (int hit = 0; hit < hits; hit += 1) {
            int penetration_roll = roll_d6(game) + weapon->strength;
            if (penetration_roll < armour_value) {
                te_log(game, "%s's %s fails to penetrate %s (roll %d vs AV %d).", attacker->name, weapon->name, target->name, penetration_roll, armour_value);
                continue;
            }

            bool glancing_hit = penetration_roll == armour_value;
            if (!glancing_hit && protective_glancing_only) {
                glancing_hit = true;
            }

            if (glancing_hit) {
                te_log(game, "%s scores a glancing hit on %s with %s.", attacker->name, target->name, weapon->name);
                apply_vehicle_damage(game, attacker, target, true);
            } else {
                te_log(game, "%s scores a penetrating hit on %s with %s.", attacker->name, target->name, weapon->name);
                apply_vehicle_damage(game, attacker, target, false);
            }
            if (target->destroyed || game_has_pending_weapon_destroy_choice(game)) {
                return;
            }
        }
        return;
    }

    if (weapon->blast_diameter > 0) {
        float marker_x = target->x;
        float marker_y = target->y;
        bool direct_hit = true;
        int scatter_distance = 0;

        if (weapon->ordnance || weapon->barrage) {
            direct_hit = scatter_marker(game, target->x, target->y, &marker_x, &marker_y, &scatter_distance);
        } else {
            int needed_to_hit = required_to_hit_ballistic(attacker->ballistic_skill);
            if (!roll_to_hit_with_linked(game, needed_to_hit, weapon->linked)) {
                te_log(game, "%s's %s misses %s.", attacker->name, weapon->name, target->name);
                return;
            }
        }

        int hits = template_hits_vehicle(target, marker_x, marker_y, weapon->blast_diameter);
        if (hits <= 0) {
            te_log(game, "%s's %s scatters away from %s.", attacker->name, weapon->name, target->name);
            return;
        }

        te_log(game, "%s lands %d blast hit%s on %s with %s (%s).", attacker->name, hits, hits == 1 ? "" : "s", target->name, weapon->name, direct_hit ? "direct hit" : "scatter");
        for (int hit = 0; hit < hits; hit += 1) {
            int penetration_roll = roll_d6(game) + weapon->strength;
            if (penetration_roll < armour_value) {
                te_log(game, "%s's %s fails to penetrate %s (roll %d vs AV %d).", attacker->name, weapon->name, target->name, penetration_roll, armour_value);
                continue;
            }

            bool glancing_hit = penetration_roll == armour_value || protective_glancing_only;
            if (glancing_hit) {
                te_log(game, "%s scores a glancing hit on %s with %s.", attacker->name, target->name, weapon->name);
                apply_vehicle_damage(game, attacker, target, true);
            } else if (weapon->ordnance) {
                te_log(game, "%s scores an ordnance hit on %s with %s.", attacker->name, target->name, weapon->name);
                apply_ordnance_vehicle_damage(game, attacker, target);
            } else {
                te_log(game, "%s scores a penetrating hit on %s with %s.", attacker->name, target->name, weapon->name);
                apply_vehicle_damage(game, attacker, target, false);
            }

            if (target->destroyed || game_has_pending_weapon_destroy_choice(game)) {
                return;
            }
        }
        return;
    }

    int needed_to_hit = required_to_hit_ballistic(attacker->ballistic_skill);
    for (int shot = 0; shot < shots; shot += 1) {
        if (!roll_to_hit_with_linked(game, needed_to_hit, weapon->linked)) {
            continue;
        }

        int penetration_roll = roll_d6(game) + weapon->strength;
        if (penetration_roll < armour_value) {
            te_log(game, "%s's %s bounces off %s (penetration %d vs AV %d).", attacker->name, weapon->name, target->name, penetration_roll, armour_value);
            continue;
        }

        bool glancing_hit = penetration_roll == armour_value;
        if (!glancing_hit && protective_glancing_only) {
            glancing_hit = true;
        }

        if (glancing_hit) {
            te_log(game, "%s scores a glancing hit on %s with %s.", attacker->name, target->name, weapon->name);
            apply_vehicle_damage(game, attacker, target, true);
        } else {
            te_log(game, "%s scores a penetrating hit on %s with %s.", attacker->name, target->name, weapon->name);
            apply_vehicle_damage(game, attacker, target, false);
        }
        if (target->destroyed || game_has_pending_weapon_destroy_choice(game)) {
            return;
        }
    }
}

static bool resolve_vehicle_follow_on_fire(game_t *game, unit_t *attacker, unit_t *target, float range, int start_weapon_index, int weapons_remaining, bool *out_resolved_any_weapon, bool *out_arc_blocked, bool *out_line_blocked, bool *out_weapon_in_range) {
    if (game == NULL || attacker == NULL || target == NULL) {
        return false;
    }

    for (int weapon_index = start_weapon_index; weapon_index < attacker->weapon_count && weapons_remaining > 0; weapon_index += 1) {
        weapon_slot_t *slot = &attacker->weapons[weapon_index];
        if (slot->destroyed) {
            continue;
        }
        if (slot->profile.ordnance && attacker->moved_distance > 0.01f) {
            continue;
        }
        if (range > (float)slot->profile.range) {
            continue;
        }
        if (out_weapon_in_range != NULL) {
            *out_weapon_in_range = true;
        }
        if (!weapon_slot_can_bear_target(attacker, target, slot)) {
            if (out_arc_blocked != NULL) {
                *out_arc_blocked = true;
            }
            continue;
        }
        if (!slot->profile.barrage && line_of_sight_blocked(game, attacker, target)) {
            if (out_line_blocked != NULL) {
                *out_line_blocked = true;
            }
            continue;
        }

        weapons_remaining -= 1;
        if (out_resolved_any_weapon != NULL) {
            *out_resolved_any_weapon = true;
        }

        int target_models_before = target->models;
        if (unit_uses_vehicle_rules(target)) {
            resolve_weapon_against_vehicle(game, attacker, target, &slot->profile, slot->profile.shots);
        } else {
            resolve_weapon_against_infantry(game, attacker, target, &slot->profile, slot->profile.shots);
        }
        record_weapon_fire_angle(attacker, target, slot);

        if (game_has_pending_hit_allocation_choice(game) || game_has_pending_weapon_destroy_choice(game)) {
            begin_pending_vehicle_shot_sequence(game, attacker, target, weapon_index + 1, weapons_remaining);
            return true;
        }

        if (target->kind == TE_UNIT_INFANTRY && target->models < target_models_before && slot->profile.barrage) {
            apply_pinning(game, target, slot->profile.ordnance ? -1 : 0, slot->profile.name);
        }
        if (target->destroyed) {
            break;
        }
    }

    clear_pending_vehicle_shot_sequence(game);
    return false;
}

static bool continue_pending_vehicle_shot_sequence(game_t *game) {
    if (!game_has_pending_vehicle_shot_sequence(game)) {
        return true;
    }

    int attacker_id = game->pending_vehicle_shot_attacker_id;
    int target_id = game->pending_vehicle_shot_target_id;
    int next_weapon_index = game->pending_vehicle_shot_next_weapon_index;
    int weapons_remaining = game->pending_vehicle_shot_weapons_remaining;
    clear_pending_vehicle_shot_sequence(game);

    unit_t *attacker = find_unit(game, attacker_id);
    unit_t *target = find_unit(game, target_id);
    if (attacker == NULL || target == NULL || attacker->destroyed || target->destroyed) {
        return true;
    }

    float range = te_distance(attacker->x, attacker->y, target->x, target->y) - attacker->footprint_radius - target->footprint_radius;
    if (range < 0.0f) {
        range = 0.0f;
    }

    te_log(game, "%s resumes its remaining fire into %s.", attacker->name, target->name);
    bool paused = resolve_vehicle_follow_on_fire(game, attacker, target, range, next_weapon_index, weapons_remaining, NULL, NULL, NULL, NULL);
    if (paused) {
        return true;
    }
    if (target->kind == TE_UNIT_INFANTRY) {
        te_apply_shooting_morale(game, target);
    }
    return true;
}

static int infantry_total_shots(const unit_t *attacker, const weapon_profile_t *weapon, float range, bool counts_as_moved, int firing_models, bool *used_stationary_volume_fire) {
    if (used_stationary_volume_fire != NULL) {
        *used_stationary_volume_fire = false;
    }

    if (firing_models <= 0 || range > (float)weapon->range) {
        return 0;
    }

    if (weapon->flame) {
        return 1;
    }

    switch (weapon->mode) {
        case TE_WEAPON_RAPID_FIRE_INTERNAL:
            if (counts_as_moved) {
                return range <= 12.0f ? firing_models : 0;
            }
            if (range <= 12.0f) {
                if (used_stationary_volume_fire != NULL) {
                    *used_stationary_volume_fire = true;
                }
                return firing_models * 2;
            }
            if (used_stationary_volume_fire != NULL) {
                *used_stationary_volume_fire = true;
            }
            return firing_models;
        case TE_WEAPON_ASSAULT_INTERNAL:
            return firing_models * weapon->shots;
        case TE_WEAPON_PISTOL_INTERNAL:
            return counts_as_moved ? firing_models : firing_models * 2;
        case TE_WEAPON_HEAVY_INTERNAL:
            if (counts_as_moved) {
                return 0;
            }
            if (used_stationary_volume_fire != NULL) {
                *used_stationary_volume_fire = true;
            }
            return firing_models * weapon->shots;
        default:
            return 0;
    }
}

static bool assert_valid_unit_action(game_t *game, const unit_t *unit) {
    if (unit == NULL) {
        return fail(game, "Unit not found.");
    }
    if (unit->destroyed) {
        return fail(game, "%s has already been destroyed.", unit->name);
    }
    if (unit_is_embarked(unit)) {
        return fail(game, "%s is embarked in a transport and cannot act directly.", unit->name);
    }
    if (unit->owner != game->active_player) {
        return fail(game, "%s does not belong to the active player.", unit->name);
    }
    return true;
}

static bool assert_valid_deployment_unit(game_t *game, const unit_t *unit) {
    if (unit == NULL) {
        return fail(game, "Unit not found.");
    }
    if (unit->destroyed) {
        return fail(game, "%s has already been destroyed.", unit->name);
    }
    if (unit_is_embarked(unit)) {
        return fail(game, "%s is embarked in a transport and cannot be positioned directly.", unit->name);
    }
    return true;
}

static void add_zone(game_t *game, int id, const char *name, terrain_kind_t kind, float x, float y, float width, float height, int cover_save, bool blocks_line_of_sight, bool hull_down) {
    zone_t *zone = &game->zones[game->zone_count];
    game->zone_count += 1;
    zone->id = id;
    zone->name = name;
    zone->kind = kind;
    zone->rect.x = x;
    zone->rect.y = y;
    zone->rect.width = width;
    zone->rect.height = height;
    zone->cover_save = cover_save;
    zone->blocks_line_of_sight = blocks_line_of_sight;
    zone->hull_down = hull_down;
}

static void add_objective(game_t *game, int id, const char *name, float x, float y, float radius) {
    objective_t *objective = &game->objectives[game->objective_count];
    game->objective_count += 1;
    objective->id = id;
    objective->name = name;
    objective->x = x;
    objective->y = y;
    objective->radius = radius;
}

static void setup_bocage_breakout_battlefield(game_t *game) {
    add_zone(game, 1, "Ruined Farmhouse", TE_TERRAIN_DIFFICULT, 26.0f, 16.0f, 18.0f, 14.0f, 5, true, false);
    add_zone(game, 2, "Bocage Ridge", TE_TERRAIN_OPEN, 8.0f, 9.0f, 10.0f, 26.0f, 5, false, true);
    add_zone(game, 3, "Shell-Hole Field", TE_TERRAIN_DIFFICULT, 46.0f, 6.0f, 14.0f, 10.0f, 6, false, false);
    add_zone(game, 4, "Marked Minefield", TE_TERRAIN_IMPASSABLE, 50.0f, 34.0f, 12.0f, 8.0f, 0, false, false);
    add_objective(game, 1, "Ammunition Cache", 35.0f, 23.0f, 5.5f);
    add_objective(game, 2, "Observation Post", 13.0f, 22.0f, 5.0f);
    add_objective(game, 3, "Road Junction", 53.0f, 11.0f, 5.0f);
    add_objective(game, 4, "Fuel Dump", 56.0f, 38.0f, 5.0f);
}

static void setup_bocage_breakout_mission(game_t *game) {
    game->mission_name = "Bocage Breakout";
    game->mission_target_score = 8;
}

static void add_unit(game_t *game, unit_t unit) {
    unit.preferred_casualty_group_index = -1;
    normalize_unit_wounds(&unit);
    game->units[game->unit_count] = unit;
    game->unit_count += 1;
}

static void setup_demo(game_t *game) {
    memset(game, 0, sizeof(*game));

    setup_bocage_breakout_battlefield(game);

    unit_t tactical = {
        .id = 1,
        .name = "British Rifle Section",
        .owner = TE_PLAYER_ONE,
        .kind = TE_UNIT_INFANTRY,
        .x = 11.0f,
        .y = 36.0f,
        .facing_degrees = 0.0f,
        .footprint_radius = 1.6f,
        .starting_models = 10,
        .models = 10,
        .weapon_skill = 4,
        .ballistic_skill = 4,
        .strength = 4,
        .toughness = 4,
        .initiative = 4,
        .attacks = 1,
        .leadership = 8,
        .save = 3,
        .weapon_count = 1,
    };
    tactical.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_LEE_ENFIELD_NO4);

    unit_t assault = {
        .id = 2,
        .name = "British Commando Section",
        .owner = TE_PLAYER_ONE,
        .kind = TE_UNIT_INFANTRY,
        .x = 15.0f,
        .y = 24.0f,
        .facing_degrees = 0.0f,
        .footprint_radius = 1.4f,
        .starting_models = 5,
        .models = 5,
        .weapon_skill = 4,
        .ballistic_skill = 4,
        .strength = 4,
        .toughness = 4,
        .initiative = 4,
        .attacks = 1,
        .leadership = 8,
        .save = 3,
        .weapon_count = 1,
    };
    assault.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_THOMPSON_SMG);

    unit_t reconVehicle = {
        .id = 3,
        .name = "Universal Carrier",
        .owner = TE_PLAYER_ONE,
        .kind = TE_UNIT_VEHICLE,
        .x = 10.0f,
        .y = 12.0f,
        .facing_degrees = 0.0f,
        .footprint_radius = 1.1f,
        .starting_models = 1,
        .models = 1,
        .weapon_skill = 0,
        .ballistic_skill = 4,
        .strength = 0,
        .toughness = 0,
        .initiative = 0,
        .attacks = 0,
        .leadership = 0,
        .save = 0,
        .front_armour = 10,
        .side_armour = 10,
        .rear_armour = 10,
        .fast = true,
        .recon = true,
        .smoke_available = true,
        .weapon_count = 1,
    };
    reconVehicle.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_BREN_LMG), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);

    unit_t firefly = {
        .id = 7,
        .name = "Sherman Firefly",
        .owner = TE_PLAYER_ONE,
        .kind = TE_UNIT_VEHICLE,
        .x = 20.0f,
        .y = 10.0f,
        .facing_degrees = 0.0f,
        .footprint_radius = 1.8f,
        .starting_models = 1,
        .models = 1,
        .ballistic_skill = 3,
        .front_armour = 14,
        .side_armour = 12,
        .rear_armour = 10,
        .smoke_available = true,
        .weapon_count = 2,
    };
    firefly.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_17_POUNDER_AT_GUN), 360), TE_WEAPON_MOUNT_TURRET_INTERNAL);
    firefly.weapons[1].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_HULL_BROWNING_M1919A4), 90), TE_WEAPON_MOUNT_FIXED_INTERNAL);

    unit_t mortar = {
        .id = 8,
        .name = "3-inch Mortar Battery",
        .owner = TE_PLAYER_ONE,
        .kind = TE_UNIT_VEHICLE,
        .x = 12.0f,
        .y = 42.0f,
        .facing_degrees = 0.0f,
        .footprint_radius = 1.6f,
        .starting_models = 1,
        .models = 1,
        .ballistic_skill = 4,
        .front_armour = 11,
        .side_armour = 11,
        .rear_armour = 10,
        .smoke_available = true,
        .weapon_count = 1,
    };
    mortar.weapons[0].profile = with_mount(wwii_weapon_profile(DZWK_WEAPON_81MM_MORTAR_BATTERY), TE_WEAPON_MOUNT_FIXED_INTERNAL);

    unit_t command = {
        .id = 9,
        .name = "British Platoon HQ",
        .owner = TE_PLAYER_ONE,
        .kind = TE_UNIT_INFANTRY,
        .x = 19.0f,
        .y = 33.0f,
        .facing_degrees = 0.0f,
        .footprint_radius = 1.3f,
        .starting_models = 5,
        .models = 5,
        .weapon_skill = 4,
        .ballistic_skill = 4,
        .strength = 4,
        .toughness = 4,
        .initiative = 4,
        .attacks = 1,
        .leadership = 8,
        .save = 3,
        .weapon_count = 1,
    };
    command.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_WEBLEY_REVOLVER);

    unit_t flamer = {
        .id = 12,
        .name = "Royal Engineers Flamethrower Team",
        .owner = TE_PLAYER_ONE,
        .kind = TE_UNIT_INFANTRY,
        .x = 25.0f,
        .y = 14.0f,
        .facing_degrees = 0.0f,
        .footprint_radius = 0.9f,
        .starting_models = 1,
        .models = 1,
        .weapon_skill = 4,
        .ballistic_skill = 4,
        .strength = 4,
        .toughness = 4,
        .initiative = 4,
        .attacks = 1,
        .leadership = 8,
        .save = 3,
        .weapon_count = 1,
    };
    flamer.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_FLAMETHROWER);

    unit_t transport = {
        .id = 10,
        .name = "Universal Carrier Transport",
        .owner = TE_PLAYER_ONE,
        .kind = TE_UNIT_VEHICLE,
        .x = 15.0f,
        .y = 33.0f,
        .facing_degrees = 0.0f,
        .footprint_radius = 1.5f,
        .starting_models = 1,
        .models = 1,
        .ballistic_skill = 4,
        .front_armour = 11,
        .side_armour = 11,
        .rear_armour = 10,
        .smoke_available = true,
        .weapon_count = 1,
        .transport_capacity = 10,
    };
    transport.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_BREN_LMG), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);

    unit_t soviet_guards = {
        .id = 13,
        .name = "Soviet Guards SMG Squad",
        .owner = TE_PLAYER_TWO,
        .kind = TE_UNIT_INFANTRY,
        .x = 24.0f,
        .y = 22.0f,
        .facing_degrees = 180.0f,
        .footprint_radius = 1.3f,
        .starting_models = 3,
        .models = 3,
        .wounds_per_model = 2,
        .weapon_skill = 4,
        .ballistic_skill = 3,
        .strength = 4,
        .toughness = 4,
        .initiative = 4,
        .attacks = 1,
        .leadership = 8,
        .save = 4,
        .weapon_count = 1,
    };
    soviet_guards.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_PPSH_41_SMG);

    unit_t bersaglieri_squad = {
        .id = 14,
        .name = "Italian Bersaglieri Squad",
        .owner = TE_PLAYER_TWO,
        .kind = TE_UNIT_INFANTRY,
        .x = 32.0f,
        .y = 19.0f,
        .facing_degrees = 180.0f,
        .footprint_radius = 1.4f,
        .starting_models = 3,
        .models = 3,
        .weapon_skill = 4,
        .ballistic_skill = 2,
        .strength = 3,
        .toughness = 2,
        .initiative = 2,
        .attacks = 1,
        .leadership = 7,
        .save = 6,
        .weapon_count = 1,
        .profile_group_count = 2,
    };
    bersaglieri_squad.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_BERETTA_M38);
    bersaglieri_squad.profile_groups[0] = (profile_group_t){
        .name = "Bersaglieri Riflemen",
        .models = 2,
        .starting_models = 2,
        .weapon_skill = 2,
        .ballistic_skill = 2,
        .strength = 2,
        .toughness = 2,
        .initiative = 2,
        .attacks = 1,
        .leadership = 5,
        .save = 6,
        .wounds_per_model = 1,
    };
    bersaglieri_squad.profile_groups[1] = (profile_group_t){
        .name = "Bersaglieri NCO",
        .models = 1,
        .starting_models = 1,
        .weapon_skill = 4,
        .ballistic_skill = 2,
        .strength = 4,
        .toughness = 4,
        .initiative = 3,
        .attacks = 2,
        .leadership = 7,
        .save = 4,
        .wounds_per_model = 2,
    };

    unit_t warriors = {
        .id = 4,
        .name = "Italian Rifle Section",
        .owner = TE_PLAYER_TWO,
        .kind = TE_UNIT_INFANTRY,
        .x = 34.0f,
        .y = 12.0f,
        .facing_degrees = 180.0f,
        .footprint_radius = 1.6f,
        .starting_models = 10,
        .models = 10,
        .weapon_skill = 4,
        .ballistic_skill = 4,
        .strength = 3,
        .toughness = 3,
        .initiative = 5,
        .attacks = 1,
        .leadership = 8,
        .save = 5,
        .weapon_count = 1,
    };
    warriors.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_CARCANO_M91);

    unit_t italian_rifle_squad = {
        .id = 5,
        .name = "Italian Rifle Squad",
        .owner = TE_PLAYER_TWO,
        .kind = TE_UNIT_INFANTRY,
        .x = 49.0f,
        .y = 24.0f,
        .facing_degrees = 180.0f,
        .footprint_radius = 1.8f,
        .starting_models = 12,
        .models = 12,
        .weapon_skill = 4,
        .ballistic_skill = 2,
        .strength = 3,
        .toughness = 4,
        .initiative = 2,
        .attacks = 1,
        .leadership = 7,
        .save = 6,
        .weapon_count = 1,
    };
    italian_rifle_squad.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_CARCANO_M91);

    unit_t buggy = {
        .id = 6,
        .name = "AB41 Armored Car",
        .owner = TE_PLAYER_TWO,
        .kind = TE_UNIT_VEHICLE,
        .x = 63.0f,
        .y = 39.0f,
        .facing_degrees = 180.0f,
        .footprint_radius = 1.0f,
        .starting_models = 1,
        .models = 1,
        .ballistic_skill = 2,
        .front_armour = 10,
        .side_armour = 10,
        .rear_armour = 10,
        .fast = true,
        .open_topped = true,
        .smoke_available = true,
        .weapon_count = 1,
    };
    buggy.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_20MM_AUTOCANNON), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);

    unit_t assaultGun = {
        .id = 11,
        .name = "Semovente 75/18",
        .owner = TE_PLAYER_TWO,
        .kind = TE_UNIT_ASSAULT_GUN,
        .x = 25.0f,
        .y = 24.0f,
        .facing_degrees = 180.0f,
        .footprint_radius = 1.5f,
        .starting_models = 1,
        .models = 1,
        .weapon_skill = 4,
        .ballistic_skill = 2,
        .strength = 10,
        .toughness = 0,
        .initiative = 2,
        .attacks = 2,
        .leadership = 0,
        .save = 0,
        .front_armour = 12,
        .side_armour = 12,
        .rear_armour = 10,
        .weapon_count = 2,
    };
    assaultGun.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_75MM_TANK_GUN), 90), TE_WEAPON_MOUNT_FIXED_INTERNAL);
    assaultGun.weapons[1].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_BREDA_M1930), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);

    add_unit(game, tactical);
    add_unit(game, assault);
    add_unit(game, reconVehicle);
    add_unit(game, firefly);
    add_unit(game, mortar);
    add_unit(game, command);
    add_unit(game, flamer);
    add_unit(game, transport);
    add_unit(game, soviet_guards);
    add_unit(game, bersaglieri_squad);
    add_unit(game, warriors);
    add_unit(game, italian_rifle_squad);
    add_unit(game, buggy);
    add_unit(game, assaultGun);

    game->player_one_army = TE_ARMY_DEMO;
    game->player_one_force = 0;
    game->player_two_army = TE_ARMY_DEMO;
    game->player_two_force = 0;
    setup_bocage_breakout_mission(game);
    game->turn_number = 1;
    game->active_player = TE_PLAYER_ONE;
    game->phase = TE_PHASE_MOVEMENT;
}

static army_list_t sanitize_army(army_list_t army) {
    switch (army) {
        case TE_ARMY_DEMO:
        case TE_ARMY_BRITISH:
        case TE_ARMY_GERMAN:
        case TE_ARMY_AUSTRALIAN:
        case TE_ARMY_ITALIAN:
        case TE_ARMY_AMERICAN:
        case TE_ARMY_SOVIET:
            return army;
        default:
            return TE_ARMY_DEMO;
    }
}

const char *army_name(army_list_t army) {
    switch (sanitize_army(army)) {
        case TE_ARMY_BRITISH:
            return "British";
        case TE_ARMY_GERMAN:
            return "German";
        case TE_ARMY_AUSTRALIAN:
            return "Australian";
        case TE_ARMY_ITALIAN:
            return "Italian";
        case TE_ARMY_AMERICAN:
            return "American";
        case TE_ARMY_SOVIET:
            return "Soviet";
        case TE_ARMY_DEMO:
        default:
            return "Training Demo";
    }
}

int army_force_count(army_list_t army) {
    switch (sanitize_army(army)) {
        case TE_ARMY_DEMO:
            return 1;
        case TE_ARMY_BRITISH:
        case TE_ARMY_GERMAN:
        case TE_ARMY_AUSTRALIAN:
        case TE_ARMY_ITALIAN:
        case TE_ARMY_AMERICAN:
        case TE_ARMY_SOVIET:
            return 2;
        default:
            return 1;
    }
}

static int sanitize_force_index(army_list_t army, int force_index) {
    int count = army_force_count(army);
    if (count <= 0) {
        return 0;
    }
    if (force_index < 0 || force_index >= count) {
        return 0;
    }
    return force_index;
}

static const char *army_force_name_internal(army_list_t army, int force_index) {
    switch (sanitize_army(army)) {
        case TE_ARMY_BRITISH:
            return force_index == 1 ? "British Armoured Troop" : "British Rifle Platoon";
        case TE_ARMY_GERMAN:
            return force_index == 1 ? "German Panzergrenadier Kampfgruppe" : "German Grenadier Platoon";
        case TE_ARMY_AUSTRALIAN:
            return force_index == 1 ? "Australian Matilda Column" : "Australian Jungle Patrol";
        case TE_ARMY_ITALIAN:
            return force_index == 1 ? "Italian Alpini Detachment" : "Italian Bersaglieri Column";
        case TE_ARMY_AMERICAN:
            return force_index == 1 ? "US Ranger Assault" : "US Armored Infantry";
        case TE_ARMY_SOVIET:
            return force_index == 1 ? "Soviet Guards Tank Riders" : "Soviet Rifle Company";
        case TE_ARMY_DEMO:
        default:
            return "Training Demo";
    }
}

static const char *army_force_summary_internal(army_list_t army, int force_index) {
    switch (sanitize_army(army)) {
        case TE_ARMY_BRITISH:
            return force_index == 1
                ? "Armoured support with tanks, carriers, engineers, and field-gun coverage."
                : "Rifle sections backed by Bren, PIAT, carrier, tank, and mortar support.";
        case TE_ARMY_GERMAN:
            return force_index == 1
                ? "Mechanized infantry, pioneers, anti-tank weapons, assault guns, and rocket artillery."
                : "Grenadiers with MG42, Panzerfaust, half-track, Panzer IV, and mortar support.";
        case TE_ARMY_AUSTRALIAN:
            return force_index == 1
                ? "Matilda-led armor with rifle, Vickers, Grant, and mortar support."
                : "Jungle patrol infantry with Owen guns, Bren, PIAT, carrier, and short 25-pounder support.";
        case TE_ARMY_ITALIAN:
            return force_index == 1
                ? "Mountain infantry with mortars, 47mm anti-tank guns, and Semovente support."
                : "Bersaglieri infantry with Breda guns, Solothurn anti-tank rifles, medium tanks, and Semoventi.";
        case TE_ARMY_AMERICAN:
            return force_index == 1
                ? "Ranger-led assault troops with SMGs, bazookas, tank destroyers, and mortar support."
                : "Armored infantry with BARs, bazookas, half-tracks, Shermans, and Priest artillery.";
        case TE_ARMY_SOVIET:
            return force_index == 1
                ? "Guards SMG troops, sappers, T-34 riders, assault guns, and Katyusha rockets."
                : "Rifle and SMG troops with DP guns, anti-tank rifles, T-34s, and mortar support.";
        case TE_ARMY_DEMO:
        default:
            return "Rules training encounter for engine smoke tests.";
    }
}

typedef unit_t (*army_catalog_factory_t)(int id, player_t owner, int slot_index);

/*
 * World War II demo roster tables:
 * The current hard-coded catalogs define the playable Allies (British,
 * American, Australian, Soviet) and Axis (German, Italian) forces. The default
 * playable demo is a British Rifle Platoon against a German Grenadier Platoon.
 * See docs/wwii_demo_scope.md for source anchors and preset planning.
 */
typedef struct {
    int id;
    int points;
    int max_count;
    army_catalog_factory_t factory;
    const char *unit_name;
    const char *source_note;
} army_catalog_entry_t;

#define DZWK_SOURCE_LEDGER "Wikipedia-backed source anchors: docs/wwii_demo_scope.md, docs/wwii_unit_profiles.md, docs/wwii_weapon_taxonomy.md, docs/wwii_armor_profiles.md"
#define DZWK_BRITISH_SOURCE_NOTE "British roster. " DZWK_SOURCE_LEDGER
#define DZWK_AMERICAN_SOURCE_NOTE "American roster. " DZWK_SOURCE_LEDGER
#define DZWK_AUSTRALIAN_SOURCE_NOTE "Australian roster. " DZWK_SOURCE_LEDGER
#define DZWK_SOVIET_SOURCE_NOTE "Soviet roster. " DZWK_SOURCE_LEDGER
#define DZWK_GERMAN_SOURCE_NOTE "German roster. " DZWK_SOURCE_LEDGER
#define DZWK_ITALIAN_SOURCE_NOTE "Italian roster. " DZWK_SOURCE_LEDGER
#define DZWK_CATALOG_ENTRY(id, points, max_count, factory, unit_name, source_note) \
    {id, points, max_count, factory, unit_name, source_note}

army_force_view_t army_force_view(army_list_t army, int index) {
    army_force_view_t view;
    memset(&view, 0, sizeof(view));

    int force_index = sanitize_force_index(army, index);
    if (index < 0 || index >= army_force_count(army)) {
        return view;
    }

    view.id = force_index;
    view.name = army_force_name_internal(army, force_index);
    view.summary = army_force_summary_internal(army, force_index);
    return view;
}

static int next_unit_id(const game_t *game) {
    return game->unit_count + 1;
}

static unit_t with_unit_name(unit_t unit, const char *name) {
    if (name != NULL && name[0] != '\0') {
        unit.name = name;
    }
    return unit;
}

static deployment_slot_t deployment_slot_for(player_t owner, int slot_index) {
    static const deployment_slot_t player_one_slots[] = {
        {11.0f, 36.0f, 0.0f},
        {15.0f, 24.0f, 0.0f},
        {10.0f, 12.0f, 0.0f},
        {20.0f, 10.0f, 0.0f},
        {12.0f, 42.0f, 0.0f},
        {19.0f, 33.0f, 0.0f},
        {25.0f, 14.0f, 0.0f},
        {15.0f, 33.0f, 0.0f},
        {23.0f, 40.0f, 0.0f},
        {28.0f, 30.0f, 0.0f},
    };
    static const deployment_slot_t player_two_slots[] = {
        {61.0f, 12.0f, 180.0f},
        {57.0f, 22.0f, 180.0f},
        {62.0f, 39.0f, 180.0f},
        {51.0f, 10.0f, 180.0f},
        {55.0f, 29.0f, 180.0f},
        {47.0f, 18.0f, 180.0f},
        {43.0f, 34.0f, 180.0f},
        {53.0f, 32.0f, 180.0f},
        {40.0f, 26.0f, 180.0f},
        {34.0f, 18.0f, 180.0f},
    };

    const deployment_slot_t *slots = owner == TE_PLAYER_ONE ? player_one_slots : player_two_slots;
    int slot_count = owner == TE_PLAYER_ONE
        ? (int)(sizeof(player_one_slots) / sizeof(player_one_slots[0]))
        : (int)(sizeof(player_two_slots) / sizeof(player_two_slots[0]));
    if (slot_index < 0) {
        slot_index = 0;
    }
    if (slot_index >= slot_count) {
        slot_index %= slot_count;
    }
    return slots[slot_index];
}

static unit_t make_infantry_unit_at_slot(int id, const char *name, player_t owner, int slot_index, float radius, int models, int wounds_per_model, int weapon_skill, int ballistic_skill, int strength, int toughness, int initiative, int attacks, int leadership, int save) {
    deployment_slot_t slot = deployment_slot_for(owner, slot_index);
    unit_t unit = {
        .id = id,
        .name = name,
        .owner = owner,
        .kind = TE_UNIT_INFANTRY,
        .x = slot.x,
        .y = slot.y,
        .facing_degrees = slot.facing_degrees,
        .footprint_radius = radius,
        .starting_models = models,
        .models = models,
        .wounds_per_model = wounds_per_model > 0 ? wounds_per_model : 1,
        .lead_model_wounds = wounds_per_model > 0 ? wounds_per_model : 1,
        .weapon_skill = weapon_skill,
        .ballistic_skill = ballistic_skill,
        .strength = strength,
        .toughness = toughness,
        .initiative = initiative,
        .attacks = attacks,
        .leadership = leadership,
        .save = save,
    };
    return unit;
}

static unit_t make_vehicle_unit_at_slot(int id, const char *name, player_t owner, int slot_index, float radius, int ballistic_skill, int front_armour, int side_armour, int rear_armour, bool fast, bool recon, bool open_topped, int transport_capacity) {
    deployment_slot_t slot = deployment_slot_for(owner, slot_index);
    unit_t unit = {
        .id = id,
        .name = name,
        .owner = owner,
        .kind = TE_UNIT_VEHICLE,
        .x = slot.x,
        .y = slot.y,
        .facing_degrees = slot.facing_degrees,
        .footprint_radius = radius,
        .starting_models = 1,
        .models = 1,
        .ballistic_skill = ballistic_skill,
        .front_armour = front_armour,
        .side_armour = side_armour,
        .rear_armour = rear_armour,
        .fast = fast,
        .recon = recon,
        .open_topped = open_topped,
        .smoke_available = true,
        .transport_capacity = transport_capacity,
    };
    return unit;
}

static unit_t make_assault_gun_unit_at_slot(int id, const char *name, player_t owner, int slot_index, float radius, int weapon_skill, int ballistic_skill, int strength, int initiative, int attacks, int front_armour, int side_armour, int rear_armour) {
    deployment_slot_t slot = deployment_slot_for(owner, slot_index);
    unit_t unit = {
        .id = id,
        .name = name,
        .owner = owner,
        .kind = TE_UNIT_ASSAULT_GUN,
        .x = slot.x,
        .y = slot.y,
        .facing_degrees = slot.facing_degrees,
        .footprint_radius = radius,
        .starting_models = 1,
        .models = 1,
        .weapon_skill = weapon_skill,
        .ballistic_skill = ballistic_skill,
        .strength = strength,
        .initiative = initiative,
        .attacks = attacks,
        .front_armour = front_armour,
        .side_armour = side_armour,
        .rear_armour = rear_armour,
    };
    return unit;
}

static unit_t make_allied_rifle_section_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "British Rifle Section", owner, slot_index, 1.6f, 10, 1, 4, 4, 4, 4, 4, 1, 8, 3);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_LEE_ENFIELD_NO4);
    return unit;
}

static unit_t make_american_rifle_squad_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "US Rifle Squad", owner, slot_index, 1.6f, 10, 1, 4, 4, 4, 4, 4, 1, 8, 3);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_M1_GARAND);
    return unit;
}

static unit_t make_commando_or_ranger_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "British Commando Section", owner, slot_index, 1.4f, 5, 1, 4, 4, 4, 4, 4, 1, 8, 3);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_THOMPSON_SMG);
    return unit;
}

static unit_t make_universal_carrier_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_vehicle_unit_at_slot(id, "Universal Carrier", owner, slot_index, 1.1f, 4, 10, 10, 10, true, true, false, 0);
    unit.weapon_count = 1;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_BREN_LMG), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);
    return unit;
}

static unit_t make_sherman_firefly_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_vehicle_unit_at_slot(id, "Sherman Firefly", owner, slot_index, 1.8f, 3, 14, 12, 10, false, false, false, 0);
    unit.weapon_count = 2;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_17_POUNDER_AT_GUN), 360), TE_WEAPON_MOUNT_TURRET_INTERNAL);
    unit.weapons[1].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_HULL_BROWNING_M1919A4), 90), TE_WEAPON_MOUNT_FIXED_INTERNAL);
    return unit;
}

static unit_t make_mortar_battery_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_vehicle_unit_at_slot(id, "3-inch Mortar Battery", owner, slot_index, 1.6f, 4, 11, 11, 10, false, false, false, 0);
    unit.weapon_count = 1;
    unit.weapons[0].profile = with_mount(wwii_weapon_profile(DZWK_WEAPON_81MM_MORTAR_BATTERY), TE_WEAPON_MOUNT_FIXED_INTERNAL);
    return unit;
}

static unit_t make_platoon_hq_unit(int id, const char *name, player_t owner, int slot_index, wwii_weapon_id_t weapon_id) {
    unit_t unit = make_infantry_unit_at_slot(id, name, owner, slot_index, 1.3f, 5, 1, 4, 4, 4, 4, 4, 1, 8, 3);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(weapon_id);
    return unit;
}

static unit_t make_command_squad_unit(int id, player_t owner, int slot_index) {
    return make_platoon_hq_unit(id, "British Platoon HQ", owner, slot_index, DZWK_WEAPON_WEBLEY_REVOLVER);
}

static unit_t make_us_command_squad_unit(int id, player_t owner, int slot_index) {
    return make_platoon_hq_unit(id, "US Platoon HQ", owner, slot_index, DZWK_WEAPON_M1911A1_PISTOL);
}

static unit_t make_flamethrower_team_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Royal Engineers Flamethrower Team", owner, slot_index, 0.9f, 1, 1, 4, 4, 4, 4, 4, 1, 8, 3);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_FLAMETHROWER);
    return unit;
}

static unit_t make_transport_unit_with_weapon(int id, player_t owner, int slot_index, const char *name, wwii_weapon_id_t weapon_id) {
    unit_t unit = make_vehicle_unit_at_slot(id, name, owner, slot_index, 1.5f, 4, 11, 11, 10, false, false, false, 10);
    unit.weapon_count = 1;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(weapon_id), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);
    return unit;
}

static unit_t make_transport_unit(int id, player_t owner, int slot_index, const char *name) {
    return make_transport_unit_with_weapon(id, owner, slot_index, name, DZWK_WEAPON_BREN_LMG);
}

static unit_t make_m3_half_track_transport_unit(int id, player_t owner, int slot_index) {
    return make_transport_unit_with_weapon(id, owner, slot_index, "M3 Half-track", DZWK_WEAPON_M2_BROWNING_HMG);
}

static unit_t make_sd_kfz_251_transport_unit(int id, player_t owner, int slot_index) {
    return make_transport_unit_with_weapon(id, owner, slot_index, "Sd.Kfz. 251 Half-track", DZWK_WEAPON_MG42);
}

static unit_t make_british_15cwt_truck_unit(int id, player_t owner, int slot_index) {
    return make_transport_unit(id, owner, slot_index, "British 15-cwt Truck");
}

static unit_t make_australian_carrier_transport_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_vehicle_unit_at_slot(id, "Australian Carrier", owner, slot_index, 1.6f, 3, 12, 10, 10, false, false, false, 10);
    unit.weapon_count = 2;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_VICKERS_HMG), 360), TE_WEAPON_MOUNT_TURRET_INTERNAL);
    unit.weapons[1].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_BREN_LMG), 90), TE_WEAPON_MOUNT_FIXED_INTERNAL);
    return unit;
}

static unit_t make_jeep_recon_patrol_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_vehicle_unit_at_slot(id, "Jeep Recon Patrol", owner, slot_index, 1.1f, 3, 10, 10, 10, true, true, false, 0);
    unit.weapon_count = 1;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_BROWNING_M1919A4), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);
    return unit;
}

static unit_t make_soviet_guards_smg_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Soviet Guards SMG Squad", owner, slot_index, 1.3f, 3, 2, 4, 3, 4, 4, 4, 1, 8, 4);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_PPSH_41_SMG);
    return unit;
}

static unit_t make_bersaglieri_squad_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Italian Bersaglieri Squad", owner, slot_index, 1.4f, 3, 1, 4, 2, 3, 2, 2, 1, 7, 6);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_BERETTA_M38);
    unit.profile_group_count = 2;
    unit.profile_groups[0] = (profile_group_t){
        .name = "Bersaglieri Riflemen",
        .models = 2,
        .starting_models = 2,
        .weapon_skill = 2,
        .ballistic_skill = 2,
        .strength = 2,
        .toughness = 2,
        .initiative = 2,
        .attacks = 1,
        .leadership = 5,
        .save = 6,
        .wounds_per_model = 1,
    };
    unit.profile_groups[1] = (profile_group_t){
        .name = "Bersaglieri NCO",
        .models = 1,
        .starting_models = 1,
        .weapon_skill = 4,
        .ballistic_skill = 2,
        .strength = 4,
        .toughness = 4,
        .initiative = 3,
        .attacks = 2,
        .leadership = 7,
        .save = 4,
        .wounds_per_model = 2,
    };
    return unit;
}

static unit_t make_italian_infantry_unit(int id, player_t owner, int slot_index, const char *name) {
    unit_t unit = make_infantry_unit_at_slot(id, name, owner, slot_index, 1.8f, 12, 1, 4, 2, 3, 4, 2, 1, 7, 6);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_CARCANO_M91);
    return unit;
}

static unit_t make_ab41_armored_car_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_vehicle_unit_at_slot(id, "AB41 Armored Car", owner, slot_index, 1.0f, 2, 10, 10, 10, true, false, true, 0);
    unit.weapon_count = 1;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_20MM_AUTOCANNON), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);
    return unit;
}

static unit_t make_semovente_assault_gun_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_assault_gun_unit_at_slot(id, "Semovente 75/18", owner, slot_index, 1.5f, 4, 2, 10, 2, 2, 12, 12, 10);
    unit.weapon_count = 2;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_75MM_TANK_GUN), 90), TE_WEAPON_MOUNT_FIXED_INTERNAL);
    unit.weapons[1].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_BREDA_M1930), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);
    return unit;
}

static unit_t make_australian_rifle_section_unit(int id, player_t owner, int slot_index, const char *name) {
    unit_t unit = make_infantry_unit_at_slot(id, name, owner, slot_index, 1.5f, 10, 1, 3, 3, 3, 3, 3, 1, 7, 5);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_LEE_ENFIELD_NO4);
    unit.profile_group_count = 2;
    unit.profile_groups[0] = (profile_group_t){
        .name = "Riflemen",
        .models = 8,
        .starting_models = 8,
        .weapon_skill = 3,
        .ballistic_skill = 3,
        .strength = 3,
        .toughness = 3,
        .initiative = 3,
        .attacks = 1,
        .leadership = 7,
        .save = 5,
        .wounds_per_model = 1,
    };
    unit.profile_groups[1] = (profile_group_t){
        .name = "Bren Team",
        .models = 2,
        .starting_models = 2,
        .weapon_skill = 3,
        .ballistic_skill = 3,
        .strength = 3,
        .toughness = 3,
        .initiative = 3,
        .attacks = 1,
        .leadership = 7,
        .save = 5,
        .wounds_per_model = 1,
    };
    return unit;
}

static unit_t make_australian_platoon_hq_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Australian Platoon HQ", owner, slot_index, 1.2f, 5, 1, 3, 3, 3, 3, 3, 1, 8, 5);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_WEBLEY_REVOLVER);
    return unit;
}

static unit_t make_australian_piat_team_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Australian PIAT Team", owner, slot_index, 1.3f, 6, 1, 3, 4, 3, 3, 3, 1, 8, 5);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_PIAT);
    return unit;
}

static unit_t make_dingo_scout_car_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_vehicle_unit_at_slot(id, "Dingo Scout Car", owner, slot_index, 1.2f, 3, 10, 10, 10, true, true, false, 0);
    unit.weapon_count = 1;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_BREN_LMG), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);
    return unit;
}

static unit_t make_vickers_mg_team_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Vickers MG Team", owner, slot_index, 1.4f, 6, 1, 3, 3, 3, 3, 3, 1, 7, 5);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_VICKERS_HMG);
    return unit;
}

static unit_t make_german_infantry_unit(int id, player_t owner, int slot_index, const char *name) {
    unit_t unit = make_infantry_unit_at_slot(id, name, owner, slot_index, 1.5f, 8, 1, 4, 4, 4, 4, 4, 1, 8, 3);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_KAR98K);
    return unit;
}

static unit_t make_german_recon_section_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "German Recon Section", owner, slot_index, 1.3f, 5, 1, 4, 4, 4, 4, 4, 1, 8, 3);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_MP40);
    return unit;
}

static unit_t make_german_mg42_team_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "German MG42 Team", owner, slot_index, 1.4f, 6, 1, 4, 4, 4, 4, 4, 1, 9, 3);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_MG42);
    return unit;
}

static unit_t make_stug_assault_gun_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_assault_gun_unit_at_slot(id, "StuG III Assault Gun", owner, slot_index, 1.5f, 4, 4, 10, 4, 2, 12, 12, 10);
    unit.weapon_count = 2;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_75MM_TANK_GUN), 90), TE_WEAPON_MOUNT_FIXED_INTERNAL);
    unit.weapons[1].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_MG42), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);
    return unit;
}

static unit_t make_soviet_rifle_squad_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Soviet Rifle Squad", owner, slot_index, 1.7f, 12, 1, 3, 2, 3, 3, 4, 1, 6, 6);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_MOSIN_NAGANT_1891_30);
    return unit;
}

static unit_t make_soviet_smg_squad_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Soviet SMG Squad", owner, slot_index, 1.7f, 12, 1, 4, 2, 3, 3, 5, 1, 6, 6);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_PPSH_41_SMG);
    return unit;
}

static unit_t make_soviet_sapper_assault_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Soviet Sapper Assault Group", owner, slot_index, 1.6f, 1, 4, 4, 2, 9, 6, 2, 2, 10, 3);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_FLAMETHROWER);
    return unit;
}

static unit_t make_soviet_sapper_squad_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Soviet Sapper Squad", owner, slot_index, 1.5f, 8, 1, 3, 3, 4, 3, 5, 1, 7, 6);
    unit.weapon_count = 1;
    unit.weapons[0].profile = wwii_weapon_profile(DZWK_WEAPON_DP27_LMG);
    return unit;
}

static unit_t make_italian_truck_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_vehicle_unit_at_slot(id, "Italian Truck", owner, slot_index, 1.3f, 2, 10, 10, 10, true, false, true, 12);
    unit.weapon_count = 1;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_BREDA_M1930), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);
    return unit;
}

static unit_t make_m10_tank_destroyer_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_assault_gun_unit_at_slot(id, "M10 Tank Destroyer", owner, slot_index, 1.5f, 4, 4, 10, 4, 2, 12, 12, 10);
    unit.weapon_count = 2;
    unit.weapons[0].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_17_POUNDER_AT_GUN), 90), TE_WEAPON_MOUNT_FIXED_INTERNAL);
    unit.weapons[1].profile = with_mount(with_fire_arc(wwii_weapon_profile(DZWK_WEAPON_M2_BROWNING_HMG), 180), TE_WEAPON_MOUNT_PINTLE_INTERNAL);
    return unit;
}

static unit_t make_soviet_scout_section_unit(int id, player_t owner, int slot_index) {
    unit_t unit = make_infantry_unit_at_slot(id, "Soviet Scout Section", owner, slot_index, 1.4f, 8, 1, 6, 0, 4, 4, 6, 2, 10, 5);
    unit.weapon_count = 0;
    return unit;
}

static unit_t make_catalog_allied_rifle_section(int id, player_t owner, int slot_index) {
    return make_allied_rifle_section_unit(id, owner, slot_index);
}

static unit_t make_catalog_american_rifle_squad(int id, player_t owner, int slot_index) {
    return make_american_rifle_squad_unit(id, owner, slot_index);
}

static unit_t make_catalog_commando_or_ranger(int id, player_t owner, int slot_index) {
    return make_commando_or_ranger_unit(id, owner, slot_index);
}

static unit_t make_catalog_universal_carrier(int id, player_t owner, int slot_index) {
    return make_universal_carrier_unit(id, owner, slot_index);
}

static unit_t make_catalog_m10_tank_destroyer(int id, player_t owner, int slot_index) {
    return make_m10_tank_destroyer_unit(id, owner, slot_index);
}

static unit_t make_catalog_sherman_firefly(int id, player_t owner, int slot_index) {
    return make_sherman_firefly_unit(id, owner, slot_index);
}

static unit_t make_catalog_mortar_battery(int id, player_t owner, int slot_index) {
    return make_mortar_battery_unit(id, owner, slot_index);
}

static unit_t make_catalog_command_squad(int id, player_t owner, int slot_index) {
    return make_command_squad_unit(id, owner, slot_index);
}

static unit_t make_catalog_us_command_squad(int id, player_t owner, int slot_index) {
    return make_us_command_squad_unit(id, owner, slot_index);
}

static unit_t make_catalog_flamethrower_team(int id, player_t owner, int slot_index) {
    return make_flamethrower_team_unit(id, owner, slot_index);
}

static unit_t make_catalog_transport_apc(int id, player_t owner, int slot_index) {
    return make_transport_unit(id, owner, slot_index, "Universal Carrier Transport");
}

static unit_t make_catalog_british_15cwt_truck(int id, player_t owner, int slot_index) {
    return make_british_15cwt_truck_unit(id, owner, slot_index);
}

static unit_t make_catalog_australian_carrier(int id, player_t owner, int slot_index) {
    return make_australian_carrier_transport_unit(id, owner, slot_index);
}

static unit_t make_catalog_m3_half_track(int id, player_t owner, int slot_index) {
    return make_m3_half_track_transport_unit(id, owner, slot_index);
}

static unit_t make_catalog_jeep_recon_patrol(int id, player_t owner, int slot_index) {
    return make_jeep_recon_patrol_unit(id, owner, slot_index);
}

static unit_t make_catalog_infantry_squad(int id, player_t owner, int slot_index) {
    return make_australian_rifle_section_unit(id, owner, slot_index, "Australian Rifle Section");
}

static unit_t make_catalog_australian_platoon_hq(int id, player_t owner, int slot_index) {
    return make_australian_platoon_hq_unit(id, owner, slot_index);
}

static unit_t make_catalog_australian_piat_team(int id, player_t owner, int slot_index) {
    return make_australian_piat_team_unit(id, owner, slot_index);
}

static unit_t make_catalog_dingo_scout_car(int id, player_t owner, int slot_index) {
    return make_dingo_scout_car_unit(id, owner, slot_index);
}

static unit_t make_catalog_vickers_mg_team(int id, player_t owner, int slot_index) {
    return make_vickers_mg_team_unit(id, owner, slot_index);
}

static unit_t make_catalog_german_grenadiers(int id, player_t owner, int slot_index) {
    return make_german_infantry_unit(id, owner, slot_index, "German Grenadier Squad");
}

static unit_t make_catalog_german_volksgrenadiers(int id, player_t owner, int slot_index) {
    return make_german_infantry_unit(id, owner, slot_index, "German Volksgrenadier Squad");
}

static unit_t make_catalog_german_recon_section(int id, player_t owner, int slot_index) {
    return make_german_recon_section_unit(id, owner, slot_index);
}

static unit_t make_catalog_german_mg42_team(int id, player_t owner, int slot_index) {
    return make_german_mg42_team_unit(id, owner, slot_index);
}

static unit_t make_catalog_german_pioneers(int id, player_t owner, int slot_index) {
    return make_german_infantry_unit(id, owner, slot_index, "German Pioneer Squad");
}

static unit_t make_catalog_sd_kfz_251(int id, player_t owner, int slot_index) {
    return make_sd_kfz_251_transport_unit(id, owner, slot_index);
}

static unit_t make_catalog_stug_assault_gun(int id, player_t owner, int slot_index) {
    return make_stug_assault_gun_unit(id, owner, slot_index);
}

static unit_t make_catalog_italian_rifle_squad(int id, player_t owner, int slot_index) {
    return make_italian_infantry_unit(id, owner, slot_index, "Italian Rifle Squad");
}

static unit_t make_catalog_bersaglieri_assault_squad(int id, player_t owner, int slot_index) {
    return make_italian_infantry_unit(id, owner, slot_index, "Bersaglieri Assault Squad");
}

static unit_t make_catalog_bersaglieri_squad(int id, player_t owner, int slot_index) {
    return make_bersaglieri_squad_unit(id, owner, slot_index);
}

static unit_t make_catalog_ab41_armored_car(int id, player_t owner, int slot_index) {
    return make_ab41_armored_car_unit(id, owner, slot_index);
}

static unit_t make_catalog_semovente_assault_gun(int id, player_t owner, int slot_index) {
    return make_semovente_assault_gun_unit(id, owner, slot_index);
}

static unit_t make_catalog_italian_truck(int id, player_t owner, int slot_index) {
    return make_italian_truck_unit(id, owner, slot_index);
}

static unit_t make_catalog_soviet_rifle_squad(int id, player_t owner, int slot_index) {
    return make_soviet_rifle_squad_unit(id, owner, slot_index);
}

static unit_t make_catalog_soviet_smg_squad(int id, player_t owner, int slot_index) {
    return make_soviet_smg_squad_unit(id, owner, slot_index);
}

static unit_t make_catalog_soviet_guards_smg(int id, player_t owner, int slot_index) {
    return make_soviet_guards_smg_unit(id, owner, slot_index);
}

static unit_t make_catalog_soviet_sapper_assault(int id, player_t owner, int slot_index) {
    return make_soviet_sapper_assault_unit(id, owner, slot_index);
}

static unit_t make_catalog_soviet_sapper_squad(int id, player_t owner, int slot_index) {
    return make_soviet_sapper_squad_unit(id, owner, slot_index);
}

static unit_t make_catalog_soviet_scout_section(int id, player_t owner, int slot_index) {
    return make_soviet_scout_section_unit(id, owner, slot_index);
}

static const army_catalog_entry_t british_catalog[] = {
    DZWK_CATALOG_ENTRY(0, 150, 2, make_catalog_allied_rifle_section, "British Rifle Section", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(1, 140, 1, make_catalog_commando_or_ranger, "British Commando Section", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(2, 65, 1, make_catalog_universal_carrier, "Universal Carrier", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(3, 155, 1, make_catalog_sherman_firefly, "Sherman Firefly", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(4, 95, 1, make_catalog_mortar_battery, "3-inch Mortar Battery", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(5, 100, 1, make_catalog_command_squad, "British Platoon HQ", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(6, 25, 2, make_catalog_flamethrower_team, "Royal Engineers Flamethrower Team", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(7, 50, 1, make_catalog_transport_apc, "Universal Carrier Transport", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(8, 80, 2, make_catalog_infantry_squad, "British Rifle Section", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(9, 40, 1, make_catalog_australian_platoon_hq, "British Forward Observer Team", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(10, 70, 1, make_catalog_australian_piat_team, "British PIAT Team", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(11, 85, 1, make_catalog_british_15cwt_truck, "British 15-cwt Truck", DZWK_BRITISH_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(12, 55, 1, make_catalog_dingo_scout_car, "Daimler Dingo Scout Car", DZWK_BRITISH_SOURCE_NOTE),
};

static const army_catalog_entry_t german_catalog[] = {
    DZWK_CATALOG_ENTRY(0, 120, 2, make_catalog_german_grenadiers, "German Grenadier Squad", DZWK_GERMAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(1, 110, 1, make_catalog_german_volksgrenadiers, "German Volksgrenadier Squad", DZWK_GERMAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(2, 140, 1, make_catalog_german_recon_section, "German Recon Section", DZWK_GERMAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(3, 120, 1, make_catalog_german_mg42_team, "German MG42 Team", DZWK_GERMAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(4, 130, 1, make_catalog_german_pioneers, "German Pioneer Squad", DZWK_GERMAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(5, 55, 1, make_catalog_sd_kfz_251, "Sd.Kfz. 251 Half-track", DZWK_GERMAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(6, 115, 1, make_catalog_stug_assault_gun, "StuG III Assault Gun", DZWK_GERMAN_SOURCE_NOTE),
};

static const army_catalog_entry_t australian_catalog[] = {
    DZWK_CATALOG_ENTRY(0, 80, 2, make_catalog_infantry_squad, "Australian Rifle Section", DZWK_AUSTRALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(1, 40, 1, make_catalog_australian_platoon_hq, "Australian Platoon HQ", DZWK_AUSTRALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(2, 70, 1, make_catalog_australian_piat_team, "Australian PIAT Team", DZWK_AUSTRALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(3, 85, 1, make_catalog_australian_carrier, "Australian Carrier", DZWK_AUSTRALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(4, 155, 1, make_catalog_sherman_firefly, "Matilda II", DZWK_AUSTRALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(5, 55, 1, make_catalog_dingo_scout_car, "Dingo Scout Car", DZWK_AUSTRALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(6, 75, 1, make_catalog_vickers_mg_team, "Vickers MG Team", DZWK_AUSTRALIAN_SOURCE_NOTE),
};

static const army_catalog_entry_t italian_catalog[] = {
    DZWK_CATALOG_ENTRY(0, 120, 2, make_catalog_italian_rifle_squad, "Italian Rifle Squad", DZWK_ITALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(1, 120, 2, make_catalog_bersaglieri_assault_squad, "Bersaglieri Assault Squad", DZWK_ITALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(2, 50, 1, make_catalog_bersaglieri_squad, "Italian Bersaglieri Squad", DZWK_ITALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(3, 50, 1, make_catalog_ab41_armored_car, "AB41 Armored Car", DZWK_ITALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(4, 110, 1, make_catalog_semovente_assault_gun, "Semovente 75/18", DZWK_ITALIAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(5, 55, 1, make_catalog_italian_truck, "Italian Truck", DZWK_ITALIAN_SOURCE_NOTE),
};

static const army_catalog_entry_t american_catalog[] = {
    DZWK_CATALOG_ENTRY(0, 150, 2, make_catalog_american_rifle_squad, "US Rifle Squad", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(1, 140, 1, make_catalog_commando_or_ranger, "US Ranger Squad", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(2, 65, 1, make_catalog_jeep_recon_patrol, "Jeep Recon Patrol", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(3, 115, 1, make_catalog_m10_tank_destroyer, "M10 Tank Destroyer", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(4, 95, 1, make_catalog_mortar_battery, "81mm Mortar Battery", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(5, 100, 1, make_catalog_us_command_squad, "US Platoon HQ", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(6, 25, 2, make_catalog_flamethrower_team, "US Engineer Flamethrower Team", DZWK_AMERICAN_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(7, 50, 1, make_catalog_m3_half_track, "M3 Half-track", DZWK_AMERICAN_SOURCE_NOTE),
};

static const army_catalog_entry_t soviet_catalog[] = {
    DZWK_CATALOG_ENTRY(0, 96, 2, make_catalog_soviet_rifle_squad, "Soviet Rifle Squad", DZWK_SOVIET_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(1, 120, 2, make_catalog_soviet_smg_squad, "Soviet SMG Squad", DZWK_SOVIET_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(2, 105, 2, make_catalog_soviet_guards_smg, "Soviet Guards SMG Squad", DZWK_SOVIET_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(3, 140, 1, make_catalog_soviet_sapper_assault, "Soviet Sapper Assault Group", DZWK_SOVIET_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(4, 96, 1, make_catalog_soviet_sapper_squad, "Soviet Sapper Squad", DZWK_SOVIET_SOURCE_NOTE),
    DZWK_CATALOG_ENTRY(5, 128, 1, make_catalog_soviet_scout_section, "Soviet Scout Section", DZWK_SOVIET_SOURCE_NOTE),
};

static const army_catalog_entry_t *army_catalog_entries_for(army_list_t army, int *out_count) {
    const army_catalog_entry_t *entries = NULL;
    int count = 0;

    switch (sanitize_army(army)) {
        case TE_ARMY_BRITISH:
            entries = british_catalog;
            count = (int)(sizeof(british_catalog) / sizeof(british_catalog[0]));
            break;
        case TE_ARMY_GERMAN:
            entries = german_catalog;
            count = (int)(sizeof(german_catalog) / sizeof(german_catalog[0]));
            break;
        case TE_ARMY_AUSTRALIAN:
            entries = australian_catalog;
            count = (int)(sizeof(australian_catalog) / sizeof(australian_catalog[0]));
            break;
        case TE_ARMY_ITALIAN:
            entries = italian_catalog;
            count = (int)(sizeof(italian_catalog) / sizeof(italian_catalog[0]));
            break;
        case TE_ARMY_AMERICAN:
            entries = american_catalog;
            count = (int)(sizeof(american_catalog) / sizeof(american_catalog[0]));
            break;
        case TE_ARMY_SOVIET:
            entries = soviet_catalog;
            count = (int)(sizeof(soviet_catalog) / sizeof(soviet_catalog[0]));
            break;
        case TE_ARMY_DEMO:
        default:
            break;
    }

    if (out_count != NULL) {
        *out_count = count;
    }
    return entries;
}

static int normalize_army_list_counts(army_list_t army, const army_list_entry_t *entries, int entry_count, int *out_counts) {
    int catalog_count = 0;
    const army_catalog_entry_t *catalog = army_catalog_entries_for(army, &catalog_count);
    if (out_counts == NULL) {
        return catalog_count;
    }

    for (int index = 0; index < TE_MAX_ARMY_CATALOG_UNITS; index += 1) {
        out_counts[index] = 0;
    }

    if (catalog == NULL || catalog_count <= 0) {
        return 0;
    }

    for (int index = 0; index < entry_count; index += 1) {
        int catalog_id = entries == NULL ? -1 : entries[index].catalog_id;
        int count = entries == NULL ? 0 : entries[index].count;
        if (catalog_id < 0 || catalog_id >= catalog_count || count <= 0) {
            continue;
        }
        out_counts[catalog_id] += count;
        if (out_counts[catalog_id] > catalog[catalog_id].max_count) {
            out_counts[catalog_id] = catalog[catalog_id].max_count;
        }
    }

    return catalog_count;
}

static void add_army_list_roster(game_t *game, player_t owner, army_list_t army, const army_list_entry_t *entries, int entry_count) {
    int catalog_count = 0;
    const army_catalog_entry_t *catalog = army_catalog_entries_for(army, &catalog_count);
    int counts[TE_MAX_ARMY_CATALOG_UNITS];
    normalize_army_list_counts(army, entries, entry_count, counts);
    if (catalog == NULL || catalog_count <= 0) {
        return;
    }

    bool has_any = false;
    for (int catalog_index = 0; catalog_index < catalog_count; catalog_index += 1) {
        if (counts[catalog_index] > 0) {
            has_any = true;
            break;
        }
    }
    if (!has_any) {
        counts[0] = 1;
    }

    int slot_index = 0;
    for (int catalog_index = 0; catalog_index < catalog_count; catalog_index += 1) {
        for (int copy_index = 0; copy_index < counts[catalog_index]; copy_index += 1) {
            if (game->unit_count >= TE_MAX_UNITS || slot_index >= TE_MAX_DEPLOYMENT_SLOTS_PER_SIDE) {
                return;
            }
            unit_t unit = catalog[catalog_index].factory(next_unit_id(game), owner, slot_index);
            add_unit(game, with_unit_name(unit, catalog[catalog_index].unit_name));
            slot_index += 1;
        }
    }
}

static void apply_army_list_posture(game_t *game, player_t owner, army_list_t army) {
    switch (sanitize_army(army)) {
        case TE_ARMY_BRITISH:
            set_starting_embarkation(game, owner, "British Platoon HQ", "Universal Carrier Transport");
            set_starting_embarkation(game, owner, "British Rifle Section", "British 15-cwt Truck");
            break;
        case TE_ARMY_GERMAN:
            set_starting_embarkation(game, owner, "German Pioneer Squad", "Sd.Kfz. 251 Half-track");
            break;
        case TE_ARMY_AUSTRALIAN:
            set_starting_embarkation(game, owner, "Australian Rifle Section", "Australian Carrier");
            break;
        case TE_ARMY_ITALIAN:
            set_starting_embarkation(game, owner, "Bersaglieri Assault Squad", "Italian Truck");
            break;
        case TE_ARMY_AMERICAN:
            set_starting_embarkation(game, owner, "US Platoon HQ", "M3 Half-track");
            break;
        case TE_ARMY_SOVIET:
        case TE_ARMY_DEMO:
        default:
            break;
    }
}

int army_catalog_unit_count(army_list_t army) {
    int count = 0;
    army_catalog_entries_for(army, &count);
    return count;
}

army_catalog_unit_view_t army_catalog_unit_view(army_list_t army, int index) {
    army_catalog_unit_view_t view;
    memset(&view, 0, sizeof(view));

    int catalog_count = 0;
    const army_catalog_entry_t *catalog = army_catalog_entries_for(army, &catalog_count);
    if (catalog == NULL || index < 0 || index >= catalog_count) {
        return view;
    }

    unit_t unit = catalog[index].factory(1, TE_PLAYER_ONE, 0);
    unit = with_unit_name(unit, catalog[index].unit_name);
    normalize_unit_wounds(&unit);

    view.catalog_id = index;
    view.name = unit.name;
    view.points = catalog[index].points;
    view.max_count = catalog[index].max_count;
    view.source_note = catalog[index].source_note;
    view.unit.name = unit.name;
    view.unit.kind = unit.kind;
    view.unit.models = unit.starting_models;
    view.unit.wounds_per_model = te_wounds_per_model(&unit);
    view.unit.total_wounds = te_total_wounds_remaining(&unit);
    view.unit.mixed_profiles = unit_has_mixed_profiles(&unit);
    view.unit.transport_capacity = unit.transport_capacity;
    view.unit.front_armour = unit.front_armour;
    view.unit.side_armour = unit.side_armour;
    view.unit.rear_armour = unit.rear_armour;
    view.unit.fast = unit.fast;
    view.unit.recon = unit.recon;
    view.unit.open_topped = unit.open_topped;
    if (unit.weapon_count > 0) {
        view.unit.primary_weapon_name = unit.weapons[0].profile.name;
    }
    return view;
}

int army_list_total_points(army_list_t army, const army_list_entry_t *entries, int entry_count) {
    int catalog_count = 0;
    const army_catalog_entry_t *catalog = army_catalog_entries_for(army, &catalog_count);
    int counts[TE_MAX_ARMY_CATALOG_UNITS];
    normalize_army_list_counts(army, entries, entry_count, counts);
    if (catalog == NULL || catalog_count <= 0) {
        return 0;
    }

    int total = 0;
    for (int index = 0; index < catalog_count; index += 1) {
        total += counts[index] * catalog[index].points;
    }
    return total;
}

static void add_army_force_roster(game_t *game, player_t owner, army_list_t army, int force_index) {
    switch (sanitize_army(army)) {
        case TE_ARMY_BRITISH:
            if (force_index == 1) {
                add_unit(game, make_australian_rifle_section_unit(next_unit_id(game), owner, 0, "British Rifle Section"));
                add_unit(game, with_unit_name(make_australian_platoon_hq_unit(next_unit_id(game), owner, 5), "British Forward Observer Team"));
                add_unit(game, with_unit_name(make_australian_piat_team_unit(next_unit_id(game), owner, 6), "British PIAT Team"));
                add_unit(game, make_british_15cwt_truck_unit(next_unit_id(game), owner, 7));
                add_unit(game, make_sherman_firefly_unit(next_unit_id(game), owner, 3));
                add_unit(game, with_unit_name(make_dingo_scout_car_unit(next_unit_id(game), owner, 2), "Daimler Dingo Scout Car"));
                add_unit(game, make_allied_rifle_section_unit(next_unit_id(game), owner, 1));
            } else {
                add_unit(game, make_allied_rifle_section_unit(next_unit_id(game), owner, 0));
                add_unit(game, make_commando_or_ranger_unit(next_unit_id(game), owner, 1));
                add_unit(game, make_universal_carrier_unit(next_unit_id(game), owner, 2));
                add_unit(game, make_sherman_firefly_unit(next_unit_id(game), owner, 3));
                add_unit(game, make_mortar_battery_unit(next_unit_id(game), owner, 4));
                add_unit(game, make_command_squad_unit(next_unit_id(game), owner, 5));
                add_unit(game, make_flamethrower_team_unit(next_unit_id(game), owner, 6));
                add_unit(game, make_transport_unit(next_unit_id(game), owner, 7, "Universal Carrier Transport"));
            }
            break;
        case TE_ARMY_GERMAN:
            add_unit(game, make_german_infantry_unit(next_unit_id(game), owner, 0, "German Grenadier Squad"));
            if (force_index == 1) {
                add_unit(game, make_german_infantry_unit(next_unit_id(game), owner, 1, "German Volksgrenadier Squad"));
            } else {
                add_unit(game, make_german_recon_section_unit(next_unit_id(game), owner, 1));
            }
            add_unit(game, make_german_mg42_team_unit(next_unit_id(game), owner, 4));
            add_unit(game, make_german_infantry_unit(next_unit_id(game), owner, 5, "German Pioneer Squad"));
            add_unit(game, make_sd_kfz_251_transport_unit(next_unit_id(game), owner, 7));
            add_unit(game, make_stug_assault_gun_unit(next_unit_id(game), owner, 3));
            break;
        case TE_ARMY_AUSTRALIAN:
            add_unit(game, make_australian_rifle_section_unit(next_unit_id(game), owner, 0, "Australian Rifle Section"));
            add_unit(game, make_australian_platoon_hq_unit(next_unit_id(game), owner, 5));
            if (force_index == 1) {
                add_unit(game, make_vickers_mg_team_unit(next_unit_id(game), owner, 6));
                add_unit(game, with_unit_name(make_sherman_firefly_unit(next_unit_id(game), owner, 3), "Matilda II"));
                add_unit(game, make_dingo_scout_car_unit(next_unit_id(game), owner, 2));
            } else {
                add_unit(game, make_australian_piat_team_unit(next_unit_id(game), owner, 6));
                add_unit(game, make_australian_carrier_transport_unit(next_unit_id(game), owner, 7));
                add_unit(game, with_unit_name(make_sherman_firefly_unit(next_unit_id(game), owner, 3), "Matilda II"));
                add_unit(game, make_dingo_scout_car_unit(next_unit_id(game), owner, 2));
            }
            break;
        case TE_ARMY_ITALIAN:
            add_unit(game, make_italian_infantry_unit(next_unit_id(game), owner, 0, "Italian Rifle Squad"));
            add_unit(game, make_italian_infantry_unit(next_unit_id(game), owner, 1, "Bersaglieri Assault Squad"));
            if (force_index == 1) {
                add_unit(game, make_italian_truck_unit(next_unit_id(game), owner, 7));
                add_unit(game, make_ab41_armored_car_unit(next_unit_id(game), owner, 2));
                add_unit(game, make_semovente_assault_gun_unit(next_unit_id(game), owner, 3));
            } else {
                add_unit(game, make_bersaglieri_squad_unit(next_unit_id(game), owner, 6));
                add_unit(game, make_ab41_armored_car_unit(next_unit_id(game), owner, 2));
                add_unit(game, make_semovente_assault_gun_unit(next_unit_id(game), owner, 3));
            }
            break;
        case TE_ARMY_AMERICAN:
            add_unit(game, make_american_rifle_squad_unit(next_unit_id(game), owner, 0));
            if (force_index == 1) {
                add_unit(game, make_m10_tank_destroyer_unit(next_unit_id(game), owner, 3));
            } else {
                add_unit(game, with_unit_name(make_commando_or_ranger_unit(next_unit_id(game), owner, 1), "US Ranger Squad"));
            }
            add_unit(game, make_jeep_recon_patrol_unit(next_unit_id(game), owner, 2));
            add_unit(game, with_unit_name(make_mortar_battery_unit(next_unit_id(game), owner, 4), "81mm Mortar Battery"));
            add_unit(game, make_us_command_squad_unit(next_unit_id(game), owner, 5));
            add_unit(game, with_unit_name(make_flamethrower_team_unit(next_unit_id(game), owner, 6), "US Engineer Flamethrower Team"));
            add_unit(game, make_m3_half_track_transport_unit(next_unit_id(game), owner, 7));
            break;
        case TE_ARMY_SOVIET:
            if (force_index == 1) {
                add_unit(game, make_soviet_smg_squad_unit(next_unit_id(game), owner, 1));
                add_unit(game, make_soviet_guards_smg_unit(next_unit_id(game), owner, 5));
                add_unit(game, make_soviet_sapper_assault_unit(next_unit_id(game), owner, 3));
                add_unit(game, make_soviet_scout_section_unit(next_unit_id(game), owner, 0));
                add_unit(game, make_soviet_sapper_squad_unit(next_unit_id(game), owner, 2));
            } else {
                add_unit(game, make_soviet_rifle_squad_unit(next_unit_id(game), owner, 0));
                add_unit(game, make_soviet_smg_squad_unit(next_unit_id(game), owner, 1));
                add_unit(game, make_soviet_guards_smg_unit(next_unit_id(game), owner, 5));
                add_unit(game, make_soviet_sapper_assault_unit(next_unit_id(game), owner, 3));
                add_unit(game, make_soviet_sapper_squad_unit(next_unit_id(game), owner, 2));
            }
            break;
        case TE_ARMY_DEMO:
        default:
            break;
    }
}

static void apply_army_force_posture(game_t *game, player_t owner, army_list_t army, int force_index) {
    switch (sanitize_army(army)) {
        case TE_ARMY_BRITISH:
            if (force_index == 1) {
                set_starting_embarkation(game, owner, "British Rifle Section", "British 15-cwt Truck");
            } else {
                set_starting_embarkation(game, owner, "British Platoon HQ", "Universal Carrier Transport");
            }
            break;
        case TE_ARMY_GERMAN:
            set_starting_embarkation(game, owner, "German Pioneer Squad", "Sd.Kfz. 251 Half-track");
            break;
        case TE_ARMY_AUSTRALIAN:
            if (force_index == 0) {
                set_starting_embarkation(game, owner, "Australian Rifle Section", "Australian Carrier");
            }
            break;
        case TE_ARMY_ITALIAN:
            if (force_index == 1) {
                set_starting_embarkation(game, owner, "Bersaglieri Assault Squad", "Italian Truck");
            }
            break;
        case TE_ARMY_AMERICAN:
            set_starting_embarkation(game, owner, "US Platoon HQ", "M3 Half-track");
            break;
        case TE_ARMY_DEMO:
        case TE_ARMY_SOVIET:
        default:
            break;
    }
}

static void setup_selected_army_demo(game_t *game, army_list_t player_one_army, int player_one_force, army_list_t player_two_army, int player_two_force) {
    memset(game, 0, sizeof(*game));

    setup_bocage_breakout_battlefield(game);

    game->player_one_army = sanitize_army(player_one_army);
    game->player_one_force = sanitize_force_index(game->player_one_army, player_one_force);
    game->player_two_army = sanitize_army(player_two_army);
    game->player_two_force = sanitize_force_index(game->player_two_army, player_two_force);
    if (game->player_one_army == TE_ARMY_DEMO || game->player_two_army == TE_ARMY_DEMO) {
        setup_demo(game);
        return;
    }

    add_army_force_roster(game, TE_PLAYER_ONE, game->player_one_army, game->player_one_force);
    add_army_force_roster(game, TE_PLAYER_TWO, game->player_two_army, game->player_two_force);
    apply_army_force_posture(game, TE_PLAYER_ONE, game->player_one_army, game->player_one_force);
    apply_army_force_posture(game, TE_PLAYER_TWO, game->player_two_army, game->player_two_force);

    setup_bocage_breakout_mission(game);
    game->turn_number = 1;
    game->active_player = TE_PLAYER_ONE;
    game->phase = TE_PHASE_MOVEMENT;
}

static void setup_skirmish(game_t *game, army_list_t player_one_army, const army_list_entry_t *player_one_entries, int player_one_entry_count, army_list_t player_two_army, const army_list_entry_t *player_two_entries, int player_two_entry_count) {
    memset(game, 0, sizeof(*game));

    setup_bocage_breakout_battlefield(game);

    game->player_one_army = sanitize_army(player_one_army);
    game->player_two_army = sanitize_army(player_two_army);
    game->player_one_force = 0;
    game->player_two_force = 0;
    if (game->player_one_army == TE_ARMY_DEMO || game->player_two_army == TE_ARMY_DEMO) {
        setup_demo(game);
        return;
    }

    add_army_list_roster(game, TE_PLAYER_ONE, game->player_one_army, player_one_entries, player_one_entry_count);
    add_army_list_roster(game, TE_PLAYER_TWO, game->player_two_army, player_two_entries, player_two_entry_count);
    apply_army_list_posture(game, TE_PLAYER_ONE, game->player_one_army);
    apply_army_list_posture(game, TE_PLAYER_TWO, game->player_two_army);

    setup_bocage_breakout_mission(game);
    game->turn_number = 1;
    game->active_player = TE_PLAYER_ONE;
    game->phase = TE_PHASE_MOVEMENT;
}

game_t *game_create_demo(uint32_t seed) {
    game_t *game = (game_t *)calloc(1, sizeof(game_t));
    if (game == NULL) {
        return NULL;
    }

    setup_demo(game);
    game_seed(game, seed);
    te_log(game, "Loaded Bocage Breakout demo encounter for World War II platoon action.");
    log_mission_briefing(game);
    begin_turn(game);
    return game;
}

game_t *game_create_demo_with_armies(uint32_t seed, army_list_t player_one_army, army_list_t player_two_army) {
    return game_create_demo_with_forces(seed, player_one_army, 0, player_two_army, 0);
}

game_t *game_create_demo_with_forces(uint32_t seed, army_list_t player_one_army, int player_one_force, army_list_t player_two_army, int player_two_force) {
    game_t *game = (game_t *)calloc(1, sizeof(game_t));
    if (game == NULL) {
        return NULL;
    }

    setup_selected_army_demo(game, player_one_army, player_one_force, player_two_army, player_two_force);
    game_seed(game, seed);
    te_log(game, "Loaded demo encounter for %s (%s) versus %s (%s).",
        army_name(game->player_one_army),
        army_force_name_internal(game->player_one_army, game->player_one_force),
        army_name(game->player_two_army),
        army_force_name_internal(game->player_two_army, game->player_two_force));
    log_mission_briefing(game);
    begin_turn(game);
    return game;
}

game_t *game_create_skirmish(uint32_t seed, army_list_t player_one_army, const army_list_entry_t *player_one_entries, int player_one_entry_count, army_list_t player_two_army, const army_list_entry_t *player_two_entries, int player_two_entry_count) {
    game_t *game = (game_t *)calloc(1, sizeof(game_t));
    if (game == NULL) {
        return NULL;
    }

    setup_skirmish(game, player_one_army, player_one_entries, player_one_entry_count, player_two_army, player_two_entries, player_two_entry_count);
    game_seed(game, seed);
    te_log(game, "Loaded operation for %s (%d pts) versus %s (%d pts).",
        army_name(game->player_one_army),
        army_list_total_points(game->player_one_army, player_one_entries, player_one_entry_count),
        army_name(game->player_two_army),
        army_list_total_points(game->player_two_army, player_two_entries, player_two_entry_count));
    log_mission_briefing(game);
    begin_turn(game);
    return game;
}

#ifdef HEINZ_GUDERIAN_GAME
static const char *copy_guderian_label(char destination[TE_GUDERIAN_LABEL_LENGTH], const char *source, const char *fallback) {
    const char *label = source != NULL && source[0] != '\0' ? source : fallback;
    snprintf(destination, TE_GUDERIAN_LABEL_LENGTH, "%s", label);
    return destination;
}

bool game_apply_guderian_scenario_board(game_t *game, const char *mission_name, int target_score, const guderian_scenario_zone_t *zones, int zone_count, const guderian_scenario_objective_t *objectives, int objective_count) {
    if (game == NULL) {
        return false;
    }
    if (target_score <= 0) {
        return fail(game, "Guderian scenario mission target score must be positive.");
    }
    if (zone_count < 0 || zone_count > TE_MAX_ZONES) {
        return fail(game, "Guderian scenario zone count %d exceeds engine capacity %d.", zone_count, TE_MAX_ZONES);
    }
    if (objective_count < 0 || objective_count > TE_MAX_OBJECTIVES) {
        return fail(game, "Guderian scenario objective count %d exceeds engine capacity %d.", objective_count, TE_MAX_OBJECTIVES);
    }
    if (zone_count > 0 && zones == NULL) {
        return fail(game, "Guderian scenario zones were not provided.");
    }
    if (objective_count > 0 && objectives == NULL) {
        return fail(game, "Guderian scenario objectives were not provided.");
    }

    game->zone_count = 0;
    game->objective_count = 0;
    game->player_one_score = 0;
    game->player_two_score = 0;
    game->mission_name = copy_guderian_label(game->guderian_mission_name, mission_name, "Guderian Scenario");
    game->mission_target_score = target_score;

    for (int index = 0; index < zone_count; index += 1) {
        const guderian_scenario_zone_t *source = &zones[index];
        if (source->rect.width <= 0.0f || source->rect.height <= 0.0f) {
            return fail(game, "Guderian scenario zone %d has an invalid rectangle.", source->id);
        }

        zone_t *zone = &game->zones[game->zone_count];
        game->zone_count += 1;
        zone->id = source->id;
        zone->name = copy_guderian_label(game->guderian_zone_names[index], source->name, "Guderian terrain");
        zone->kind = source->kind;
        zone->rect = source->rect;
        zone->cover_save = source->cover_save;
        zone->blocks_line_of_sight = source->blocks_line_of_sight;
        zone->hull_down = source->hull_down;
    }

    for (int index = 0; index < objective_count; index += 1) {
        const guderian_scenario_objective_t *source = &objectives[index];
        if (source->radius <= 0.0f) {
            return fail(game, "Guderian scenario objective %d has an invalid radius.", source->id);
        }

        objective_t *objective = &game->objectives[game->objective_count];
        game->objective_count += 1;
        objective->id = source->id;
        objective->name = copy_guderian_label(game->guderian_objective_names[index], source->name, "Guderian objective");
        objective->x = source->x;
        objective->y = source->y;
        objective->radius = source->radius;
    }

    clear_error(game);
    te_log(game, "Loaded Guderian scenario board with %d terrain zones and %d objectives.", game->zone_count, game->objective_count);
    log_mission_briefing(game);
    return true;
}
#endif

void game_destroy(game_t *game) {
    free(game);
}

void game_seed(game_t *game, uint32_t seed) {
    if (game == NULL) {
        return;
    }
    game->rng_state = seed == 0 ? 0xA341316Cu : seed;
}

void game_reset_demo(game_t *game, uint32_t seed) {
    if (game == NULL) {
        return;
    }
    setup_demo(game);
    game_seed(game, seed);
    te_log(game, "Reset demo encounter.");
    log_mission_briefing(game);
    begin_turn(game);
}

void game_reset_demo_with_armies(game_t *game, uint32_t seed, army_list_t player_one_army, army_list_t player_two_army) {
    game_reset_demo_with_forces(game, seed, player_one_army, 0, player_two_army, 0);
}

void game_reset_demo_with_forces(game_t *game, uint32_t seed, army_list_t player_one_army, int player_one_force, army_list_t player_two_army, int player_two_force) {
    if (game == NULL) {
        return;
    }
    setup_selected_army_demo(game, player_one_army, player_one_force, player_two_army, player_two_force);
    game_seed(game, seed);
    te_log(game, "Reset demo encounter for %s (%s) versus %s (%s).",
        army_name(game->player_one_army),
        army_force_name_internal(game->player_one_army, game->player_one_force),
        army_name(game->player_two_army),
        army_force_name_internal(game->player_two_army, game->player_two_force));
    log_mission_briefing(game);
    begin_turn(game);
}

void game_reset_skirmish(game_t *game, uint32_t seed, army_list_t player_one_army, const army_list_entry_t *player_one_entries, int player_one_entry_count, army_list_t player_two_army, const army_list_entry_t *player_two_entries, int player_two_entry_count) {
    if (game == NULL) {
        return;
    }

    setup_skirmish(game, player_one_army, player_one_entries, player_one_entry_count, player_two_army, player_two_entries, player_two_entry_count);
    game_seed(game, seed);
    te_log(game, "Reset operation for %s (%d pts) versus %s (%d pts).",
        army_name(game->player_one_army),
        army_list_total_points(game->player_one_army, player_one_entries, player_one_entry_count),
        army_name(game->player_two_army),
        army_list_total_points(game->player_two_army, player_two_entries, player_two_entry_count));
    log_mission_briefing(game);
    begin_turn(game);
}

army_list_t game_player_army(const game_t *game, player_t player) {
    if (game == NULL) {
        return TE_ARMY_DEMO;
    }
    if (player == TE_PLAYER_ONE) {
        return game->player_one_army;
    }
    if (player == TE_PLAYER_TWO) {
        return game->player_two_army;
    }
    return TE_ARMY_DEMO;
}

int game_player_force(const game_t *game, player_t player) {
    if (game == NULL) {
        return 0;
    }
    if (player == TE_PLAYER_ONE) {
        return game->player_one_force;
    }
    if (player == TE_PLAYER_TWO) {
        return game->player_two_force;
    }
    return 0;
}

int army_roster_unit_count(army_list_t army) {
    return army_force_roster_unit_count(army, 0);
}

army_roster_unit_view_t army_roster_unit_view(army_list_t army, int index) {
    return army_force_roster_unit_view(army, 0, index);
}

int army_force_roster_unit_count(army_list_t army, int force_index) {
    game_t preview_game;
    memset(&preview_game, 0, sizeof(preview_game));
    int sanitized_force = sanitize_force_index(army, force_index);
    add_army_force_roster(&preview_game, TE_PLAYER_ONE, army, sanitized_force);
    apply_army_force_posture(&preview_game, TE_PLAYER_ONE, army, sanitized_force);
    return preview_game.unit_count;
}

army_roster_unit_view_t army_force_roster_unit_view(army_list_t army, int force_index, int index) {
    army_roster_unit_view_t view;
    memset(&view, 0, sizeof(view));

    game_t preview_game;
    memset(&preview_game, 0, sizeof(preview_game));
    int sanitized_force = sanitize_force_index(army, force_index);
    add_army_force_roster(&preview_game, TE_PLAYER_ONE, army, sanitized_force);
    apply_army_force_posture(&preview_game, TE_PLAYER_ONE, army, sanitized_force);
    if (index < 0 || index >= preview_game.unit_count) {
        return view;
    }

    const unit_t *unit = &preview_game.units[index];
    view.name = unit->name;
    view.kind = unit->kind;
    view.models = unit->starting_models;
    view.wounds_per_model = te_wounds_per_model(unit);
    view.total_wounds = te_total_wounds_remaining(unit);
    view.mixed_profiles = unit_has_mixed_profiles(unit);
    view.transport_capacity = unit->transport_capacity;
    view.front_armour = unit->front_armour;
    view.side_armour = unit->side_armour;
    view.rear_armour = unit->rear_armour;
    view.fast = unit->fast;
    view.recon = unit->recon;
    view.open_topped = unit->open_topped;
    if (unit->weapon_count > 0) {
        view.primary_weapon_name = unit->weapons[0].profile.name;
    }
    if (unit->embarked_unit_id > 0) {
        const unit_t *passenger = find_unit_const(&preview_game, unit->embarked_unit_id);
        view.embarked_unit_name = passenger == NULL ? NULL : passenger->name;
    }
    if (unit->embarked_in_transport_id > 0) {
        const unit_t *transport = find_unit_const(&preview_game, unit->embarked_in_transport_id);
        view.embarked_transport_name = transport == NULL ? NULL : transport->name;
    }
    return view;
}

game_view_t game_view(const game_t *game) {
    game_view_t view;
    memset(&view, 0, sizeof(view));
    if (game == NULL) {
        return view;
    }
    view.turn_number = game->turn_number;
    view.active_player = game->active_player;
    view.phase = game->phase;
    return view;
}

mission_view_t game_mission_view(const game_t *game) {
    mission_view_t view;
    memset(&view, 0, sizeof(view));
    if (game == NULL) {
        return view;
    }
    view.name = game->mission_name;
    view.target_score = game->mission_target_score;
    view.player_one_score = game->player_one_score;
    view.player_two_score = game->player_two_score;
    view.winner = mission_winner(game);
    return view;
}

int game_unit_count(const game_t *game) {
    return game == NULL ? 0 : game->unit_count;
}

unit_view_t game_unit_view(const game_t *game, int index) {
    unit_view_t view;
    memset(&view, 0, sizeof(view));
    if (game == NULL || index < 0 || index >= game->unit_count) {
        return view;
    }

    const unit_t *unit = &game->units[index];
    view.id = unit->id;
    view.name = unit->name;
    view.owner = unit->owner;
    view.kind = unit->kind;
    view.x = unit->x;
    view.y = unit->y;
    view.facing_degrees = unit->facing_degrees;
    view.footprint_radius = unit->footprint_radius;
    view.models = unit->models;
    view.wounds_per_model = te_wounds_per_model(unit);
    view.lead_model_wounds = unit->models > 0 ? unit->lead_model_wounds : 0;
    view.total_wounds_remaining = te_total_wounds_remaining(unit);
    view.mixed_profiles = unit_has_mixed_profiles(unit);
    view.starting_models = unit->starting_models;
    view.weapon_skill = unit->weapon_skill;
    view.ballistic_skill = unit->ballistic_skill;
    view.strength = unit->strength;
    view.toughness = unit->toughness;
    view.initiative = unit->initiative;
    view.attacks = unit->attacks;
    view.leadership = unit->leadership;
    view.save = unit->save;
    view.front_armour = unit->front_armour;
    view.side_armour = unit->side_armour;
    view.rear_armour = unit->rear_armour;
    view.fast = unit->fast;
    view.recon = unit->recon;
    view.open_topped = unit->open_topped;
    view.in_cover = cover_save_for_unit(game, unit) > 0;
    view.hull_down = hull_down_for_unit(game, unit);
    view.smoke_available = unit->smoke_available;
    view.smoke_active = unit->smoke_active;
    view.moved_this_turn = unit->moved_this_turn;
    view.can_move_now = unit_can_move_now(game, unit);
    view.shot_this_turn = unit->shot_this_turn;
    view.assaulted_this_turn = unit->assaulted_this_turn;
    view.can_shoot_now = unit_can_shoot_now(game, unit);
    view.can_assault_now = unit_can_assault_now(game, unit);
    view.locked_in_assault = unit->locked_in_assault;
    view.pinned = unit->pinned_until_turn > 0;
    view.falling_back = unit->falling_back;
    view.embarked = unit_is_embarked(unit);
    view.embarked_unit_id = unit->embarked_unit_id;
    view.embarked_in_transport_id = unit->embarked_in_transport_id;
    view.transport_capacity = unit->transport_capacity;
    view.destroyed = unit->destroyed;
    return view;
}

int game_zone_count(const game_t *game) {
    return game == NULL ? 0 : game->zone_count;
}

zone_view_t game_zone_view(const game_t *game, int index) {
    zone_view_t view;
    memset(&view, 0, sizeof(view));
    if (game == NULL || index < 0 || index >= game->zone_count) {
        return view;
    }

    const zone_t *zone = &game->zones[index];
    view.id = zone->id;
    view.name = zone->name;
    view.kind = zone->kind;
    view.rect = zone->rect;
    view.cover_save = zone->cover_save;
    view.blocks_line_of_sight = zone->blocks_line_of_sight;
    view.hull_down = zone->hull_down;
    return view;
}

int game_objective_count(const game_t *game) {
    return game == NULL ? 0 : game->objective_count;
}

objective_view_t game_objective_view(const game_t *game, int index) {
    objective_view_t view;
    memset(&view, 0, sizeof(view));
    if (game == NULL || index < 0 || index >= game->objective_count) {
        return view;
    }

    const objective_t *objective = &game->objectives[index];
    view.id = objective->id;
    view.name = objective->name;
    view.x = objective->x;
    view.y = objective->y;
    view.radius = objective->radius;
    view.controller = evaluate_objective(game, objective, &view.player_one_presence, &view.player_two_presence);
    return view;
}

int game_log_count(const game_t *game) {
    return game == NULL ? 0 : game->log_count;
}

const char *game_log_line(const game_t *game, int index) {
    if (game == NULL || index < 0 || index >= game->log_count) {
        return "";
    }
    return game->logs[index];
}

const char *game_last_error(const game_t *game) {
    if (game == NULL || game->last_error[0] == '\0') {
        return "";
    }
    return game->last_error;
}

pending_weapon_destroy_view_t game_pending_weapon_destroy_view(const game_t *game) {
    pending_weapon_destroy_view_t view;
    memset(&view, 0, sizeof(view));
    if (!game_has_pending_weapon_destroy_choice(game)) {
        return view;
    }

    const unit_t *chooser = find_unit_const(game, game->pending_weapon_destroy_chooser_id);
    const unit_t *target = find_unit_const(game, game->pending_weapon_destroy_target_id);
    view.active = true;
    view.chooser_id = game->pending_weapon_destroy_chooser_id;
    view.chooser_owner = chooser != NULL ? chooser->owner : TE_PLAYER_NONE;
    view.chooser_name = chooser != NULL ? chooser->name : "Attacker";
    view.target_id = game->pending_weapon_destroy_target_id;
    view.target_name = target != NULL ? target->name : "Vehicle";
    return view;
}

pending_hit_allocation_view_t game_pending_hit_allocation_view(const game_t *game) {
    pending_hit_allocation_view_t view;
    memset(&view, 0, sizeof(view));
    if (!game_has_pending_hit_allocation_choice(game)) {
        return view;
    }

    const unit_t *target = find_unit_const(game, game->pending_hit_allocation_target_id);
    view.active = true;
    view.chooser_owner = game->pending_hit_allocation_chooser_owner;
    view.attacker_name = game->pending_hit_allocation_attacker_name;
    view.source_name = game->pending_hit_allocation_source_name;
    view.target_id = game->pending_hit_allocation_target_id;
    view.target_name = target != NULL ? target->name : "Mixed-profile unit";
    view.hits_assigned = game->pending_hit_allocation_total_hits - game->pending_hit_allocation_hits_remaining;
    view.hits_remaining = game->pending_hit_allocation_hits_remaining;
    view.total_hits = game->pending_hit_allocation_total_hits;
    return view;
}

int game_unit_profile_group_count(const game_t *game, int unit_id) {
    const unit_t *unit = find_unit_const(game, unit_id);
    if (unit == NULL || !unit_has_profile_groups(unit)) {
        return 0;
    }
    return unit->profile_group_count;
}

profile_group_view_t game_unit_profile_group_view(const game_t *game, int unit_id, int index) {
    profile_group_view_t view;
    memset(&view, 0, sizeof(view));

    const unit_t *unit = find_unit_const(game, unit_id);
    if (unit == NULL || !unit_has_profile_groups(unit) || index < 0 || index >= unit->profile_group_count) {
        return view;
    }

    const profile_group_t *group = &unit->profile_groups[index];
    if (group->models <= 0) {
        view.index = index;
        view.name = group->name;
        return view;
    }

    view.index = index;
    view.name = group->name;
    view.models = group->models;
    view.wounds_per_model = profile_group_wounds_per_model(group);
    view.lead_model_wounds = group->lead_model_wounds;
    view.weapon_skill = profile_group_weapon_skill(unit, group);
    view.ballistic_skill = profile_group_ballistic_skill(unit, group);
    view.strength = profile_group_strength(unit, group);
    view.toughness = group->toughness;
    view.initiative = profile_group_initiative(unit, group);
    view.attacks = profile_group_attacks(unit, group);
    view.leadership = profile_group_leadership(unit, group);
    view.save = group->save;
    view.preferred_casualty_group = unit->preferred_casualty_group_index == index;
    if (game_has_pending_hit_allocation_choice(game) && game->pending_hit_allocation_target_id == unit->id) {
        view.pending_allocated_hits = game->pending_hit_allocation_allocated_hits[index];
    }
    return view;
}

int game_pending_weapon_destroy_option_count(const game_t *game) {
    if (!game_has_pending_weapon_destroy_choice(game)) {
        return 0;
    }
    return game->pending_weapon_destroy_option_count;
}

vehicle_weapon_view_t game_pending_weapon_destroy_option_view(const game_t *game, int index) {
    vehicle_weapon_view_t view;
    memset(&view, 0, sizeof(view));
    if (!game_has_pending_weapon_destroy_choice(game) || index < 0 || index >= game->pending_weapon_destroy_option_count) {
        return view;
    }

    const unit_t *target = find_unit_const(game, game->pending_weapon_destroy_target_id);
    if (target == NULL) {
        return view;
    }

    int weapon_index = game->pending_weapon_destroy_option_indices[index];
    if (weapon_index < 0 || weapon_index >= target->weapon_count) {
        return view;
    }

    view.weapon_index = weapon_index;
    view.name = target->weapons[weapon_index].profile.name;
    return view;
}

bool game_move_unit(game_t *game, int unit_id, float x, float y) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *unit = find_unit(game, unit_id);
    if (!assert_valid_unit_action(game, unit)) {
        return false;
    }
    if (!unit_can_move_now(game, unit)) {
        if (game->phase != TE_PHASE_MOVEMENT) {
            return fail(game, "Units can only move in the movement phase.");
        }
        if (unit->falling_back) {
            return fail(game, "%s is falling back and cannot be given a normal move.", unit->name);
        }
        if (unit->pinned_until_turn == game->turn_number) {
            return fail(game, "%s is pinned and cannot move this turn.", unit->name);
        }
        if (unit->locked_in_assault) {
            return fail(game, "%s is locked in close combat.", unit->name);
        }
        if (unit_uses_vehicle_rules(unit) && unit->crew_stunned) {
            return fail(game, "%s is crew stunned and cannot move.", unit->name);
        }
        if (unit_uses_vehicle_rules(unit) && unit->immobilized) {
            return fail(game, "%s is immobilized.", unit->name);
        }
        if (unit->movement_action_used_this_turn) {
            return fail(game, "%s has already used its movement for this turn.", unit->name);
        }
        return fail(game, "%s cannot move right now.", unit->name);
    }

    if (x < unit->footprint_radius || y < unit->footprint_radius || x > TE_BOARD_WIDTH - unit->footprint_radius || y > TE_BOARD_HEIGHT - unit->footprint_radius) {
        return fail(game, "Destination is outside the battlefield.");
    }

    bool touches_impassable = path_touches_terrain(game, unit->x, unit->y, x, y, TE_TERRAIN_IMPASSABLE);
    bool touches_difficult = path_touches_terrain(game, unit->x, unit->y, x, y, TE_TERRAIN_DIFFICULT);

    if (touches_impassable) {
        return fail(game, "%s cannot cross impassable terrain.", unit->name);
    }

    if (unit->kind == TE_UNIT_VEHICLE && !unit->recon && touches_difficult) {
        int terrain_roll = roll_d6(game);
        if (terrain_roll == 1) {
            unit->immobilized = true;
            te_log(game, "%s becomes immobilized entering difficult terrain.", unit->name);
            return true;
        }
        te_log(game, "%s passes a difficult terrain test on a %d.", unit->name, terrain_roll);
    }

    if (unit->recon && touches_difficult) {
        int terrain_roll = roll_d6(game);
        if (terrain_roll == 1) {
            unit->immobilized = true;
            te_log(game, "%s bogs down crossing rough ground.", unit->name);
            return true;
        }
        te_log(game, "%s clears the rough ground on a %d.", unit->name, terrain_roll);
    }

    float distance = te_distance(unit->x, unit->y, x, y);
    int allowance = best_movement_allowance(game, unit, touches_difficult && (unit->kind != TE_UNIT_VEHICLE || unit->kind == TE_UNIT_ASSAULT_GUN));
    if (distance > (float)allowance + 0.01f) {
        return fail(game, "%s can move up to %d\" this phase, not %.1f\".", unit->name, allowance, distance);
    }

    for (int index = 0; index < game->unit_count; index += 1) {
        const unit_t *enemy = &game->units[index];
        if (enemy->owner == unit->owner || enemy->destroyed || unit_is_embarked(enemy)) {
            continue;
        }
        float separation = te_distance(x, y, enemy->x, enemy->y) - unit->footprint_radius - enemy->footprint_radius;
        if (separation < 1.0f) {
            return fail(game, "%s must end at least 1\" away from enemy models.", unit->name);
        }
    }

    unit->x = x;
    unit->y = y;
    unit->moved_this_turn = true;
    unit->movement_action_used_this_turn = true;
    unit->moved_distance = distance;
    if (unit_is_transport(unit)) {
        sync_embarked_unit_position(game, unit);
    }
    te_log(game, "%s moves %.1f\".", unit->name, distance);
    return true;
}

bool game_deploy_unit(game_t *game, int unit_id, float x, float y) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *unit = find_unit(game, unit_id);
    if (!assert_valid_deployment_unit(game, unit)) {
        return false;
    }

    if (x < unit->footprint_radius || y < unit->footprint_radius || x > TE_BOARD_WIDTH - unit->footprint_radius || y > TE_BOARD_HEIGHT - unit->footprint_radius) {
        return fail(game, "Deployment position is outside the battlefield.");
    }
    if (path_touches_terrain(game, x, y, x, y, TE_TERRAIN_IMPASSABLE)) {
        return fail(game, "%s cannot be deployed in impassable terrain.", unit->name);
    }

    for (int index = 0; index < game->unit_count; index += 1) {
        const unit_t *other = &game->units[index];
        if (other->destroyed || other->id == unit->id || unit_is_embarked(other)) {
            continue;
        }

        float separation = te_distance(x, y, other->x, other->y) - unit->footprint_radius - other->footprint_radius;
        if (other->owner != unit->owner && separation < 1.0f) {
            return fail(game, "%s must deploy at least 1\" away from enemy units.", unit->name);
        }
        if (other->owner == unit->owner && separation < 0.25f) {
            return fail(game, "%s cannot overlap another friendly unit while deploying.", unit->name);
        }
    }

    unit->x = x;
    unit->y = y;
    if (unit_is_transport(unit)) {
        sync_embarked_unit_position(game, unit);
    }
    te_log(game, "%s is deployed to (%.1f\", %.1f\").", unit->name, x, y);
    return true;
}

bool game_tank_shock_unit(game_t *game, int attacker_id, int target_id) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *attacker = find_unit(game, attacker_id);
    unit_t *target = find_unit(game, target_id);
    if (!assert_valid_unit_action(game, attacker)) {
        return false;
    }
    if (target == NULL || target->destroyed) {
        return fail(game, "Target is not available.");
    }
    if (unit_is_embarked(target)) {
        return fail(game, "Embarked units cannot be targeted directly.");
    }
    if (unit_is_embarked(target)) {
        return fail(game, "Embarked units cannot be tank shocked.");
    }
    if (game->phase != TE_PHASE_MOVEMENT) {
        return fail(game, "Tank shock can only be used in the movement phase.");
    }
    if (attacker->kind != TE_UNIT_VEHICLE) {
        return fail(game, "Only vehicles can perform tank shock.");
    }
    if (unit_uses_vehicle_rules(target)) {
        return fail(game, "Tank shock is only implemented against infantry units.");
    }
    if (attacker->owner == target->owner) {
        return fail(game, "You cannot tank shock your own troops.");
    }
    if (attacker->moved_this_turn) {
        return fail(game, "%s has already moved this phase.", attacker->name);
    }
    if (attacker->crew_stunned || attacker->immobilized) {
        return fail(game, "%s cannot tank shock because it cannot move.", attacker->name);
    }

    float center_distance = te_distance(attacker->x, attacker->y, target->x, target->y);
    float edge_distance = center_distance - attacker->footprint_radius - target->footprint_radius;
    int allowance = attacker->fast ? 24 : 12;
    if (edge_distance > (float)allowance + 0.01f) {
        return fail(game, "%s cannot reach %s for tank shock.", attacker->name, target->name);
    }

    int morale_target = target->leadership;
    if (target->models * 2 < target->starting_models) {
        morale_target -= 1;
    }
    if (morale_target < 2) {
        morale_target = 2;
    }

    int morale_roll = roll_2d6(game);
    te_log(game, "%s tank shocks %s. Morale roll %d vs modified Leadership %d.", attacker->name, target->name, morale_roll, morale_target);

    bool halted = false;
    float move_distance = fminf((float)allowance, center_distance + attacker->footprint_radius + target->footprint_radius + 1.0f);

    if (morale_roll > morale_target) {
        resolve_fall_back(game, target, roll_2d6(game));
    } else {
        int weapon_strength = target->weapon_count > 0 ? target->weapons[0].profile.strength : target->strength;
        if (weapon_strength + 6 >= attacker->front_armour) {
            te_log(game, "%s attempts Death or Glory with %s.", target->name, target->weapon_count > 0 ? target->weapons[0].profile.name : "improvised attacks");
            int penetration_roll = roll_d6(game) + weapon_strength;
            if (penetration_roll >= attacker->front_armour) {
                bool glancing_hit = penetration_roll == attacker->front_armour;
                te_log(game, "%s hits automatically for %s on the front armour.", target->name, glancing_hit ? "a glancing hit" : "a penetrating hit");
                apply_vehicle_damage(game, target, attacker, glancing_hit);
                halted = attacker->destroyed || attacker->crew_stunned || attacker->immobilized;
            } else {
                te_log(game, "%s's Death or Glory attack fails to penetrate.", target->name);
            }

            if (!halted && !attacker->destroyed && target->models > 0) {
                target->models -= 1;
                normalize_unit_wounds(target);
                te_log(game, "%s is crushed beneath %s during the failed Death or Glory attack.", target->name, attacker->name);
                if (target->models <= 0) {
                    destroy_unit(game, target, "its last model was crushed under a tank shock");
                }
            }
        } else {
            te_log(game, "%s dives aside and holds position as %s grinds through.", target->name, attacker->name);
        }
    }

    if (!attacker->destroyed) {
        if (halted) {
            float stop_distance = fmaxf(edge_distance - 1.0f, 0.0f);
            move_toward_point(attacker, target->x, target->y, stop_distance);
            attacker->moved_distance = stop_distance;
            te_log(game, "%s is halted 1\" in front of the unit.", attacker->name);
        } else {
            move_toward_point(attacker, target->x, target->y, move_distance);
            attacker->moved_distance = move_distance;
            te_log(game, "%s rumbles %.1f\" through the position.", attacker->name, move_distance);
        }
        attacker->moved_this_turn = true;
        attacker->movement_action_used_this_turn = true;
        if (unit_is_transport(attacker)) {
            sync_embarked_unit_position(game, attacker);
        }
    }

    return true;
}

bool game_embark_unit(game_t *game, int unit_id, int transport_id) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *unit = find_unit(game, unit_id);
    unit_t *transport = find_unit(game, transport_id);

    if (!assert_valid_unit_action(game, unit)) {
        return false;
    }
    if (transport == NULL || transport->destroyed) {
        return fail(game, "Transport is not available.");
    }
    if (transport->owner != unit->owner) {
        return fail(game, "Units can only embark into friendly transports.");
    }
    if (!unit_is_transport(transport)) {
        return fail(game, "%s is not configured as a transport.", transport->name);
    }
    if (transport->owner != game->active_player) {
        return fail(game, "%s does not belong to the active player.", transport->name);
    }
    if (unit->kind != TE_UNIT_INFANTRY) {
        return fail(game, "Only infantry units can embark in this ruleset.");
    }
    if (unit->locked_in_assault || unit->falling_back) {
        return fail(game, "%s cannot embark while locked or falling back.", unit->name);
    }
    if (unit->pinned_until_turn == game->turn_number) {
        return fail(game, "%s is pinned and cannot embark this turn.", unit->name);
    }
    if (transport->embarked_unit_id > 0) {
        return fail(game, "%s already has passengers aboard.", transport->name);
    }
    if (transport->transport_capacity < unit->models) {
        return fail(game, "%s cannot carry %s.", transport->name, unit->name);
    }
    if (game->phase != TE_PHASE_MOVEMENT) {
        return fail(game, "Embarking is currently implemented in the movement phase only.");
    }

    float edge_distance = edge_distance_between_units(unit, transport);
    if (edge_distance > 2.0f + 0.01f) {
        return fail(game, "%s must be within 2\" of %s to embark.", unit->name, transport->name);
    }

    transport->embarked_unit_id = unit->id;
    unit->embarked_in_transport_id = transport->id;
    unit->embarked_this_turn = true;
    unit->moved_this_turn = true;
    unit->movement_action_used_this_turn = true;
    unit->x = transport->x;
    unit->y = transport->y;
    unit->facing_degrees = transport->facing_degrees;
    te_log(game, "%s embarks into %s.", unit->name, transport->name);
    return true;
}

bool game_disembark_unit(game_t *game, int transport_id) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *transport = find_unit(game, transport_id);
    if (!assert_valid_unit_action(game, transport)) {
        return false;
    }
    if (!unit_is_transport(transport)) {
        return fail(game, "%s is not configured as a transport.", transport->name);
    }
    if (game->phase != TE_PHASE_MOVEMENT) {
        return fail(game, "Disembarking is handled in the movement phase.");
    }
    if (transport->crew_stunned) {
        return fail(game, "%s is crew stunned, so embarked troops may not disembark.", transport->name);
    }

    unit_t *passenger = embarked_unit(game, transport);
    if (passenger == NULL || passenger->destroyed) {
        return fail(game, "%s has no embarked unit to deploy.", transport->name);
    }
    if (passenger->embarked_this_turn) {
        return fail(game, "%s embarked this turn and cannot disembark again now.", passenger->name);
    }
    if (transport->moved_distance > 12.0f + 0.01f) {
        return fail(game, "%s moved too far to allow disembarkation.", transport->name);
    }

    float disembark_x = transport->x;
    float disembark_y = transport->y;
    if (!find_disembark_position(game, transport, passenger, &disembark_x, &disembark_y)) {
        return fail(game, "No legal disembarkation position is available around %s.", transport->name);
    }

    transport->embarked_unit_id = 0;
    passenger->embarked_in_transport_id = 0;
    passenger->embarked_this_turn = false;
    passenger->x = disembark_x;
    passenger->y = disembark_y;
    passenger->facing_degrees = transport->facing_degrees;
    passenger->moved_this_turn = true;
    passenger->movement_action_used_this_turn = transport->moved_this_turn;
    te_log(game, "%s disembarks from %s.", passenger->name, transport->name);

    if (transport->moved_this_turn) {
        te_log(game, "%s moved first, so %s may deploy but cannot make an additional move.", transport->name, passenger->name);
    } else {
        te_log(game, "%s deployed before %s moved and may still make its normal move.", passenger->name, transport->name);
    }

    return true;
}

bool game_fire_passenger(game_t *game, int transport_id, int target_id) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *transport = find_unit(game, transport_id);
    unit_t *target = find_unit(game, target_id);

    if (!assert_valid_unit_action(game, transport)) {
        return false;
    }
    if (!unit_is_transport(transport)) {
        return fail(game, "%s is not configured as a transport.", transport->name);
    }
    if (game->phase != TE_PHASE_SHOOTING) {
        return fail(game, "Passengers can only fire in the shooting phase.");
    }
    if (target == NULL || target->destroyed) {
        return fail(game, "Target is not available.");
    }
    if (unit_is_embarked(target)) {
        return fail(game, "Embarked units cannot be targeted directly.");
    }
    if (target->owner == transport->owner) {
        return fail(game, "Passengers cannot target their own side.");
    }
    if (target->locked_in_assault) {
        return fail(game, "You cannot fire into close combat.");
    }

    unit_t *passenger = embarked_unit(game, transport);
    if (passenger == NULL || passenger->destroyed) {
        return fail(game, "%s has no embarked unit able to fire.", transport->name);
    }
    if (passenger->shot_this_turn) {
        return fail(game, "%s has already fired this turn.", passenger->name);
    }
    if (passenger->pinned_until_turn == game->turn_number) {
        return fail(game, "%s is pinned and cannot fire from %s.", passenger->name, transport->name);
    }
    if (passenger->falling_back) {
        return fail(game, "%s is falling back and cannot fire from %s.", passenger->name, transport->name);
    }
    if (transport->moved_distance > 12.0f + 0.01f) {
        return fail(game, "%s moved too fast for passengers to fire.", transport->name);
    }

    weapon_slot_t *slot = &passenger->weapons[0];
    if (slot->destroyed) {
        return fail(game, "%s has no operational ranged weapon.", passenger->name);
    }

    float range = te_distance(transport->x, transport->y, target->x, target->y) - transport->footprint_radius - target->footprint_radius;
    if (range < 0.0f) {
        range = 0.0f;
    }
    if (range > (float)slot->profile.range) {
        return fail(game, "%s is out of range for embarked fire.", target->name);
    }
    if (!transport_passenger_has_arc(transport, target)) {
        return fail(game, "%s cannot bring its firing points to bear on %s.", transport->name, target->name);
    }
    if (!slot->profile.barrage && line_of_sight_blocked(game, transport, target)) {
        return fail(game, "%s has no clear line of fire from %s.", passenger->name, transport->name);
    }

    int firing_models = transport->open_topped ? passenger->models : (passenger->models + 1) / 2;
    bool used_stationary_volume_fire = false;
    int total_shots = infantry_total_shots(passenger, &slot->profile, range, transport->moved_this_turn, firing_models, &used_stationary_volume_fire);
    if (total_shots <= 0) {
        return fail(game, "%s has no valid embarked shots at %.1f\".", passenger->name, range);
    }

    unit_t firing_platform = *passenger;
    firing_platform.x = transport->x;
    firing_platform.y = transport->y;
    firing_platform.facing_degrees = transport->facing_degrees;
    firing_platform.footprint_radius = transport->footprint_radius;
    firing_platform.models = firing_models;
    firing_platform.moved_this_turn = transport->moved_this_turn;

    te_log(game, "%s fires from %s with %d model%s.", passenger->name, transport->name, firing_models, firing_models == 1 ? "" : "s");
    int target_models_before = target->models;
    if (unit_uses_vehicle_rules(target)) {
        resolve_weapon_against_vehicle(game, &firing_platform, target, &slot->profile, total_shots);
    } else {
        resolve_weapon_against_infantry(game, &firing_platform, target, &slot->profile, total_shots);
    }

    passenger->shot_this_turn = true;
    if (used_stationary_volume_fire) {
        passenger->fired_stationary_rapid_or_heavy = true;
    }
    if (game_has_pending_hit_allocation_choice(game)) {
        return true;
    }
    if (target->kind == TE_UNIT_INFANTRY) {
        if (target->models < target_models_before && slot->profile.barrage) {
            apply_pinning(game, target, slot->profile.ordnance ? -1 : 0, slot->profile.name);
        }
        te_apply_shooting_morale(game, target);
    }
    return true;
}

bool game_rotate_unit(game_t *game, int unit_id, float facing_degrees) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *unit = find_unit(game, unit_id);
    if (!assert_valid_unit_action(game, unit)) {
        return false;
    }
    if (game->phase != TE_PHASE_MOVEMENT) {
        return fail(game, "Facing changes are only handled in the movement phase.");
    }
    if (unit_uses_vehicle_rules(unit) && unit->immobilized) {
        return fail(game, "%s is immobilized and may not turn in place.", unit->name);
    }
    unit->facing_degrees = normalize_angle(facing_degrees);
    if (unit_is_transport(unit)) {
        sync_embarked_unit_position(game, unit);
    }
    te_log(game, "%s pivots to %.0f°.", unit->name, unit->facing_degrees);
    return true;
}

bool game_deploy_rotate_unit(game_t *game, int unit_id, float facing_degrees) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *unit = find_unit(game, unit_id);
    if (!assert_valid_deployment_unit(game, unit)) {
        return false;
    }

    unit->facing_degrees = normalize_angle(facing_degrees);
    if (unit_is_transport(unit)) {
        sync_embarked_unit_position(game, unit);
    }
    te_log(game, "%s is set to face %.0f° for deployment.", unit->name, unit->facing_degrees);
    return true;
}

bool game_shoot_unit(game_t *game, int attacker_id, int target_id) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *attacker = find_unit(game, attacker_id);
    unit_t *target = find_unit(game, target_id);

    if (!assert_valid_unit_action(game, attacker)) {
        return false;
    }
    if (target == NULL || target->destroyed) {
        return fail(game, "Target is not available.");
    }
    if (unit_is_embarked(target)) {
        return fail(game, "Embarked units cannot be targeted directly.");
    }
    if (game->phase != TE_PHASE_SHOOTING) {
        return fail(game, "Units can only shoot in the shooting phase.");
    }
    if (target->owner == attacker->owner) {
        return fail(game, "Units cannot target their own side.");
    }
    if (attacker->shot_this_turn) {
        return fail(game, "%s has already shot this turn.", attacker->name);
    }
    if (!unit_can_shoot_now(game, attacker)) {
        return fail(game, "%s cannot shoot right now.", attacker->name);
    }
    if (target->locked_in_assault) {
        return fail(game, "You cannot fire into close combat.");
    }

    float range = te_distance(attacker->x, attacker->y, target->x, target->y) - attacker->footprint_radius - target->footprint_radius;
    if (range < 0.0f) {
        range = 0.0f;
    }

    bool resolved_any_weapon = false;
    bool arc_blocked = false;
    bool line_blocked = false;
    bool weapon_in_range = false;

    if (unit_uses_vehicle_rules(attacker)) {
        weapon_slot_t *ordnance_slot = NULL;
        int weapons_remaining = vehicle_max_weapons(attacker);
        if (weapons_remaining <= 0) {
            return fail(game, "%s moved too fast to fire.", attacker->name);
        }

        if (attacker->moved_distance <= 0.01f) {
            for (int weapon_index = 0; weapon_index < attacker->weapon_count; weapon_index += 1) {
                weapon_slot_t *candidate = &attacker->weapons[weapon_index];
                if (candidate->destroyed || !candidate->profile.ordnance) {
                    continue;
                }
                if (range > (float)candidate->profile.range) {
                    continue;
                }
                weapon_in_range = true;
                if (!weapon_slot_can_bear_target(attacker, target, candidate)) {
                    arc_blocked = true;
                    continue;
                }
                if (!candidate->profile.barrage && line_of_sight_blocked(game, attacker, target)) {
                    line_blocked = true;
                    continue;
                }
                ordnance_slot = candidate;
                break;
            }
        }

        if (ordnance_slot != NULL) {
            resolved_any_weapon = true;
            int target_models_before = target->models;
            if (unit_uses_vehicle_rules(target)) {
                resolve_weapon_against_vehicle(game, attacker, target, &ordnance_slot->profile, 1);
            } else {
                resolve_weapon_against_infantry(game, attacker, target, &ordnance_slot->profile, 1);
                if (target->models < target_models_before && ordnance_slot->profile.barrage) {
                    apply_pinning(game, target, ordnance_slot->profile.ordnance ? -1 : 0, ordnance_slot->profile.name);
                }
            }
            record_weapon_fire_angle(attacker, target, ordnance_slot);
            if (target->destroyed || game_has_pending_weapon_destroy_choice(game)) {
                attacker->shot_this_turn = true;
                if (target->kind == TE_UNIT_INFANTRY) {
                    te_apply_shooting_morale(game, target);
                }
                return true;
            }
        } else {
            bool paused = resolve_vehicle_follow_on_fire(game, attacker, target, range, 0, weapons_remaining, &resolved_any_weapon, &arc_blocked, &line_blocked, &weapon_in_range);
            if (paused) {
                attacker->shot_this_turn = true;
                return true;
            }
        }
    } else {
        weapon_slot_t *slot = &attacker->weapons[0];
        if (slot->destroyed) {
            return fail(game, "%s has no operational ranged weapon.", attacker->name);
        }
        weapon_in_range = range <= (float)slot->profile.range;
        if (!slot->profile.barrage && line_of_sight_blocked(game, attacker, target)) {
            return fail(game, "%s does not have line of sight to %s.", attacker->name, target->name);
        }

        bool used_stationary_volume_fire = false;
        int total_shots = infantry_total_shots(attacker, &slot->profile, range, attacker->moved_this_turn, attacker->models, &used_stationary_volume_fire);
        if (used_stationary_volume_fire) {
            attacker->fired_stationary_rapid_or_heavy = true;
        }
        if (total_shots <= 0) {
            return fail(game, "%s has no valid shots at %.1f\".", attacker->name, range);
        }

        resolved_any_weapon = true;
        int target_models_before = target->models;
        if (unit_uses_vehicle_rules(target)) {
            resolve_weapon_against_vehicle(game, attacker, target, &slot->profile, total_shots);
        } else {
            resolve_weapon_against_infantry(game, attacker, target, &slot->profile, total_shots);
            if (target->models < target_models_before && slot->profile.barrage) {
                apply_pinning(game, target, slot->profile.ordnance ? -1 : 0, slot->profile.name);
            }
        }
    }

    if (game_has_pending_hit_allocation_choice(game)) {
        attacker->shot_this_turn = true;
        return true;
    }

    if (!resolved_any_weapon) {
        if (arc_blocked && !line_blocked) {
            return fail(game, "%s has no vehicle weapon with an arc to %s.", attacker->name, target->name);
        }
        if (line_blocked && !arc_blocked) {
            return fail(game, "%s has no clear line of fire to %s.", attacker->name, target->name);
        }
        if (weapon_in_range && arc_blocked && line_blocked) {
            return fail(game, "%s has no clear weapon arc or line of fire to %s.", attacker->name, target->name);
        }
        return fail(game, "%s has no valid weapon in range or line of sight.", attacker->name);
    }

    attacker->shot_this_turn = true;
    if (target->kind == TE_UNIT_INFANTRY) {
        te_apply_shooting_morale(game, target);
    }
    return true;
}

static int melee_hits_for_profile_group(game_t *game, int models, int attacks, int attacker_ws, int defender_ws, bool charging) {
    int total_attacks = models * (attacks + (charging ? 1 : 0));
    int needed_to_hit = required_to_hit_melee(attacker_ws, defender_ws);
    int hits = 0;

    for (int roll = 0; roll < total_attacks; roll += 1) {
        if (roll_d6(game) < needed_to_hit) {
            continue;
        }
        hits += 1;
    }

    return hits;
}

static int unit_models_at_initiative(const unit_t *unit, int initiative) {
    if (unit == NULL || unit->destroyed || unit->models <= 0 || initiative <= 0) {
        return 0;
    }

    if (unit_has_profile_groups(unit)) {
        int models = 0;
        for (int index = 0; index < unit->profile_group_count; index += 1) {
            const profile_group_t *group = &unit->profile_groups[index];
            if (group->models <= 0 || profile_group_initiative(unit, group) != initiative) {
                continue;
            }
            models += group->models;
        }
        return models;
    }

    return unit->initiative == initiative ? unit->models : 0;
}

static float estimated_melee_model_frontage(const unit_t *unit) {
    if (unit == NULL) {
        return 1.0f;
    }

    int reference_models = unit->starting_models > 0 ? unit->starting_models : unit->models;
    if (reference_models <= 1) {
        return fmaxf(unit->footprint_radius * 2.0f, 0.75f);
    }

    float frontage = (unit->footprint_radius * 2.0f) / sqrtf((float)reference_models);
    return fmaxf(frontage, 0.75f);
}

static int melee_engaged_model_cap(const unit_t *attacker, const unit_t *engagement_target) {
    if (attacker == NULL || engagement_target == NULL || attacker->destroyed || engagement_target->destroyed || attacker->models <= 0) {
        return 0;
    }

    float attacker_frontage = estimated_melee_model_frontage(attacker);
    float defending_half_circumference = (float)M_PI * fmaxf(engagement_target->footprint_radius, 0.5f);
    int contact_models = (int)floorf(defending_half_circumference / attacker_frontage + 0.001f);
    if (contact_models < 1) {
        contact_models = 1;
    }

    int engaged_models = contact_models * 2;
    if (engaged_models < 1) {
        engaged_models = 1;
    }
    if (engaged_models > attacker->models) {
        engaged_models = attacker->models;
    }
    return engaged_models;
}

static void log_melee_engagement_cap(game_t *game, const unit_t *attacker, const unit_t *engagement_target, int initiative, int engaged_models, int available_models) {
    if (game == NULL || attacker == NULL || engagement_target == NULL || engaged_models <= 0 || available_models <= engaged_models) {
        return;
    }

    te_log(
        game,
        "%s can only bring %d of %d models to bear on %s at Initiative %d.",
        attacker->name,
        engaged_models,
        available_models,
        engagement_target->name,
        initiative
    );
}

static bool unit_has_melee_initiative_band(const unit_t *unit, int initiative) {
    if (unit == NULL || unit->destroyed || unit->models <= 0 || initiative <= 0) {
        return false;
    }

    if (unit_has_profile_groups(unit)) {
        for (int index = 0; index < unit->profile_group_count; index += 1) {
            const profile_group_t *group = &unit->profile_groups[index];
            if (group->models <= 0) {
                continue;
            }
            if (profile_group_initiative(unit, group) == initiative) {
                return true;
            }
        }
        return false;
    }

    return unit->initiative == initiative;
}

static int highest_melee_initiative_band(const unit_t *left, const unit_t *right) {
    const unit_t *units[2] = { left, right };
    int highest = 0;

    for (int unit_index = 0; unit_index < 2; unit_index += 1) {
        const unit_t *unit = units[unit_index];
        if (unit == NULL || unit->destroyed || unit->models <= 0) {
            continue;
        }

        if (unit_has_profile_groups(unit)) {
            for (int group_index = 0; group_index < unit->profile_group_count; group_index += 1) {
                const profile_group_t *group = &unit->profile_groups[group_index];
                if (group->models <= 0) {
                    continue;
                }

                int group_initiative = profile_group_initiative(unit, group);
                if (group_initiative > highest) {
                    highest = group_initiative;
                }
            }
            continue;
        }

        if (unit->initiative > highest) {
            highest = unit->initiative;
        }
    }

    return highest;
}

static int resolve_uniform_melee_wounds(game_t *game, const char *source_name, int strength, unit_t *defender, int hits) {
    if (hits <= 0) {
        te_log(game, "%s fails to land a telling blow on %s in melee.", source_name, defender->name);
        return 0;
    }

    int needed_to_wound = required_to_wound(strength, defender->toughness);
    int wounds = 0;
    int unsaved_wounds = 0;

    for (int hit = 0; hit < hits; hit += 1) {
        if (needed_to_wound > 6 || roll_d6(game) < needed_to_wound) {
            continue;
        }

        wounds += 1;
        if (defender->save > 0 && roll_save(game, defender->save)) {
            continue;
        }

        unsaved_wounds += 1;
    }

    te_log(game, "%s converts %d melee hit%s into %d wound%s and %d unsaved on %s.", source_name, hits, hits == 1 ? "" : "s", wounds, wounds == 1 ? "" : "s", unsaved_wounds, defender->name);
    return apply_infantry_damage(game, defender, unsaved_wounds, strength, source_name, false, NULL);
}

static int resolve_mixed_melee_wounds(game_t *game, const char *attacker_name, const char *source_name, int strength, unit_t *defender, int hits, bool allow_pending_choice) {
    if (hits <= 0) {
        te_log(game, "%s fails to land a telling blow on %s in melee.", source_name, defender->name);
        return 0;
    }

    if (allow_pending_choice && live_profile_group_count(defender) > 1 && defender->preferred_casualty_group_index < 0) {
        begin_pending_melee_hit_allocation_choice(game, attacker_name, source_name, defender, strength, hits);
        return 0;
    }

    int allocated_hits[TE_MAX_PROFILE_GROUPS];
    memset(allocated_hits, 0, sizeof(allocated_hits));
    allocate_hits_to_profile_groups(defender, hits, allocated_hits);
    return resolve_allocated_mixed_melee_hits(game, source_name, strength, defender, allocated_hits);
}

static int resolve_melee_infantry_damage_at_initiative(game_t *game, const unit_t *attacker, const unit_t *engagement_target, unit_t *defender, bool charging, int initiative, bool allow_pending_choice) {
    if (attacker == NULL || engagement_target == NULL || defender == NULL || attacker->destroyed || engagement_target->destroyed || defender->destroyed || attacker->models <= 0 || defender->models <= 0) {
        return 0;
    }

    int models_at_initiative = unit_models_at_initiative(attacker, initiative);
    if (models_at_initiative <= 0) {
        return 0;
    }

    int engaged_models_remaining = melee_engaged_model_cap(attacker, engagement_target);
    if (engaged_models_remaining > models_at_initiative) {
        engaged_models_remaining = models_at_initiative;
    }
    log_melee_engagement_cap(game, attacker, engagement_target, initiative, engaged_models_remaining, models_at_initiative);

    if (unit_has_profile_groups(attacker)) {
        int total_unsaved_wounds = 0;

        for (int index = 0; index < attacker->profile_group_count; index += 1) {
            const profile_group_t *group = &attacker->profile_groups[index];
            if (group->models <= 0 || profile_group_initiative(attacker, group) != initiative || engaged_models_remaining <= 0) {
                continue;
            }

            char source_name[TE_LOG_LINE_LENGTH];
            snprintf(source_name, sizeof(source_name), "%s in %s", group->name, attacker->name);
            int engaged_group_models = group->models;
            if (engaged_group_models > engaged_models_remaining) {
                engaged_group_models = engaged_models_remaining;
            }
            int hits = melee_hits_for_profile_group(
                game,
                engaged_group_models,
                profile_group_attacks(attacker, group),
                profile_group_weapon_skill(attacker, group),
                engagement_target->weapon_skill,
                charging
            );
            engaged_models_remaining -= engaged_group_models;

            if (unit_has_profile_groups(defender)) {
                total_unsaved_wounds += resolve_mixed_melee_wounds(game, attacker->name, source_name, profile_group_strength(attacker, group), defender, hits, allow_pending_choice);
            } else {
                total_unsaved_wounds += resolve_uniform_melee_wounds(game, source_name, profile_group_strength(attacker, group), defender, hits);
            }

            if (game_has_pending_hit_allocation_choice(game)) {
                break;
            }
            if (defender->destroyed) {
                break;
            }
        }

        return total_unsaved_wounds;
    }

    if (attacker->initiative != initiative || engaged_models_remaining <= 0) {
        return 0;
    }

    int hits = melee_hits_for_profile_group(game, engaged_models_remaining, attacker->attacks, attacker->weapon_skill, engagement_target->weapon_skill, charging);
    if (unit_has_profile_groups(defender)) {
        return resolve_mixed_melee_wounds(game, attacker->name, attacker->name, attacker->strength, defender, hits, allow_pending_choice);
    }

    return resolve_uniform_melee_wounds(game, attacker->name, attacker->strength, defender, hits);
}

static bool resolve_melee_infantry_damage_sequence(
    game_t *game,
    const unit_t *attacker,
    unit_t *defender,
    bool charging,
    bool allow_pending_choice,
    int start_initiative,
    int *io_total_unsaved_wounds,
    int *out_resolved_initiative
) {
    if (io_total_unsaved_wounds == NULL) {
        return false;
    }

    int highest_initiative = start_initiative > 0 ? start_initiative : highest_melee_initiative_band(attacker, attacker);
    for (int initiative = highest_initiative; initiative >= 1; initiative -= 1) {
        if (defender->destroyed || defender->models <= 0) {
            break;
        }
        *io_total_unsaved_wounds += resolve_melee_infantry_damage_at_initiative(game, attacker, defender, defender, charging, initiative, allow_pending_choice);
        if (game_has_pending_hit_allocation_choice(game)) {
            if (out_resolved_initiative != NULL) {
                *out_resolved_initiative = initiative;
            }
            return true;
        }
    }

    return false;
}

static int resolve_melee_infantry_damage(game_t *game, const unit_t *attacker, unit_t *defender, bool charging) {
    int total_unsaved_wounds = 0;
    (void)resolve_melee_infantry_damage_sequence(game, attacker, defender, charging, false, 0, &total_unsaved_wounds, NULL);
    return total_unsaved_wounds;
}

static bool resolve_banded_infantry_close_combat(
    game_t *game,
    unit_t *attacker,
    unit_t *target,
    bool charging,
    follow_up_t follow_up,
    int *out_attacker_wounds,
    int *out_defender_wounds,
    int start_initiative
) {
    if (game == NULL || attacker == NULL || target == NULL) {
        return false;
    }

    int highest_initiative = start_initiative > 0 ? start_initiative : highest_melee_initiative_band(attacker, target);
    for (int initiative = highest_initiative; initiative >= 1; initiative -= 1) {
        if (attacker->destroyed || target->destroyed || attacker->models <= 0 || target->models <= 0) {
            break;
        }

        bool attacker_has_band = unit_has_melee_initiative_band(attacker, initiative);
        bool target_has_band = unit_has_melee_initiative_band(target, initiative);
        if (!attacker_has_band && !target_has_band) {
            continue;
        }

        if (attacker_has_band && target_has_band) {
            unit_t attacker_source = *attacker;
            unit_t target_source = *target;
            int simultaneous_attacker_wounds = resolve_melee_infantry_damage_at_initiative(game, &attacker_source, &target_source, target, charging, initiative, true);
            if (game_has_pending_hit_allocation_choice(game)) {
                begin_pending_simultaneous_melee_resolution(
                    game,
                    attacker,
                    target,
                    follow_up,
                    charging,
                    initiative,
                    initiative - 1,
                    out_attacker_wounds != NULL ? *out_attacker_wounds : 0,
                    out_defender_wounds != NULL ? *out_defender_wounds : 0,
                    0,
                    0,
                    true,
                    TE_PENDING_SIMULTANEOUS_MELEE_RESOLVE_COUNTER,
                    &target_source
                );
                return true;
            }

            int simultaneous_defender_wounds = resolve_melee_infantry_damage_at_initiative(game, &target_source, &attacker_source, attacker, false, initiative, true);
            if (game_has_pending_hit_allocation_choice(game)) {
                if (out_attacker_wounds != NULL) {
                    *out_attacker_wounds += simultaneous_attacker_wounds;
                }
                begin_pending_simultaneous_melee_resolution(
                    game,
                    attacker,
                    target,
                    follow_up,
                    charging,
                    initiative,
                    initiative - 1,
                    out_attacker_wounds != NULL ? *out_attacker_wounds : simultaneous_attacker_wounds,
                    out_defender_wounds != NULL ? *out_defender_wounds : 0,
                    simultaneous_attacker_wounds,
                    0,
                    false,
                    TE_PENDING_SIMULTANEOUS_MELEE_CONTINUE_BANDS,
                    NULL
                );
                return true;
            }

            if (out_attacker_wounds != NULL) {
                *out_attacker_wounds += simultaneous_attacker_wounds;
            }
            if (out_defender_wounds != NULL) {
                *out_defender_wounds += simultaneous_defender_wounds;
            }

            te_log(game, "Initiative %d is simultaneous: %s deals %d wound%s and %s deals %d wound%s.", initiative, attacker->name, simultaneous_attacker_wounds, simultaneous_attacker_wounds == 1 ? "" : "s", target->name, simultaneous_defender_wounds, simultaneous_defender_wounds == 1 ? "" : "s");
            continue;
        }

        if (attacker_has_band) {
            int wounds = resolve_melee_infantry_damage_at_initiative(game, attacker, target, target, charging, initiative, true);
            if (game_has_pending_hit_allocation_choice(game)) {
                begin_pending_banded_melee_resolution(
                    game,
                    attacker,
                    target,
                    follow_up,
                    charging,
                    initiative - 1,
                    out_attacker_wounds != NULL ? *out_attacker_wounds : 0,
                    out_defender_wounds != NULL ? *out_defender_wounds : 0,
                    true,
                    initiative
                );
                return true;
            }
            if (out_attacker_wounds != NULL) {
                *out_attacker_wounds += wounds;
            }
            te_log(game, "%s inflicts %d unsaved wound%s in melee at Initiative %d.", attacker->name, wounds, wounds == 1 ? "" : "s", initiative);
            continue;
        }

        int counter_wounds = resolve_melee_infantry_damage_at_initiative(game, target, attacker, attacker, false, initiative, true);
        if (game_has_pending_hit_allocation_choice(game)) {
            begin_pending_banded_melee_resolution(
                game,
                attacker,
                target,
                follow_up,
                charging,
                initiative - 1,
                out_attacker_wounds != NULL ? *out_attacker_wounds : 0,
                out_defender_wounds != NULL ? *out_defender_wounds : 0,
                false,
                initiative
            );
            return true;
        }
        if (out_defender_wounds != NULL) {
            *out_defender_wounds += counter_wounds;
        }
        te_log(game, "%s inflicts %d unsaved wound%s in melee at Initiative %d.", target->name, counter_wounds, counter_wounds == 1 ? "" : "s", initiative);
    }

    return false;
}

static int close_combat_modifier(const unit_t *winner, const unit_t *loser) {
    int modifier = 0;
    if (loser->models * 2 < loser->starting_models) {
        modifier -= 1;
    }

    if (winner->models >= loser->models * 4 && loser->models > 0) {
        modifier -= 4;
    } else if (winner->models >= loser->models * 3 && loser->models > 0) {
        modifier -= 3;
    } else if (winner->models >= loser->models * 2 && loser->models > 0) {
        modifier -= 2;
    } else if (winner->models > loser->models) {
        modifier -= 1;
    }

    return modifier;
}

static int required_to_hit_vehicle_in_assault(const unit_t *vehicle) {
    if (vehicle->recon) {
        return 6;
    }
    if (vehicle->moved_distance <= 0.01f) {
        return 1;
    }
    if (vehicle->moved_distance <= 6.0f) {
        return 4;
    }
    return 6;
}

static int melee_vehicle_damage_results(game_t *game, const unit_t *attacker, unit_t *defender, bool charging, float attack_origin_x, float attack_origin_y) {
    int attacks = attacker->models * (attacker->attacks + (charging ? 1 : 0));
    int hits = 0;
    int damaging_hits = 0;
    int armour_value = vehicle_armour_for_arc(defender, attack_origin_x, attack_origin_y);
    bool hit_by_weapon_skill = defender->kind == TE_UNIT_ASSAULT_GUN;
    int needed_to_hit = hit_by_weapon_skill ? required_to_hit_melee(attacker->weapon_skill, defender->weapon_skill) : required_to_hit_vehicle_in_assault(defender);

    for (int roll = 0; roll < attacks; roll += 1) {
        bool hit = needed_to_hit <= 1 || roll_d6(game) >= needed_to_hit;
        if (!hit) {
            continue;
        }

        hits += 1;
        int penetration_roll = roll_d6(game) + attacker->strength;
        if (penetration_roll < armour_value) {
            continue;
        }

        bool glancing_hit = penetration_roll == armour_value;
        damaging_hits += 1;
        te_log(game, "%s scores %s on %s in close combat.", attacker->name, glancing_hit ? "a glancing hit" : "a penetrating hit", defender->name);
        apply_vehicle_damage(game, attacker, defender, glancing_hit);
        if (defender->destroyed || game_has_pending_weapon_destroy_choice(game)) {
            break;
        }
    }

    if (!defender->destroyed) {
        if (needed_to_hit <= 1) {
            te_log(game, "%s hits %s automatically in close combat: %d hit%s and %d damaging result%s.", attacker->name, defender->name, hits, hits == 1 ? "" : "s", damaging_hits, damaging_hits == 1 ? "" : "s");
        } else {
            te_log(game, "%s attacks %s in close combat on %d+: %d hit%s and %d damaging result%s.", attacker->name, defender->name, needed_to_hit, hits, hits == 1 ? "" : "s", damaging_hits, damaging_hits == 1 ? "" : "s");
        }
    }

    return damaging_hits;
}

static void consolidate_after_wiping_out_enemy(game_t *game, unit_t *winner, const unit_t *loser) {
    if (game == NULL || winner == NULL || loser == NULL || winner->destroyed) {
        return;
    }

    float moved = move_toward_point_legally(game, winner, loser->x, loser->y, 3.0f, -1);
    if (moved < 0.01f) {
        te_log(game, "%s cannot consolidate after destroying %s without entering a new combat in the current token model.", winner->name, loser->name);
        return;
    }
    if (moved + 0.01f < 3.0f) {
        te_log(game, "%s consolidates %.1f\" after destroying %s in close combat, stopping short of a new combat.", winner->name, moved, loser->name);
        return;
    }
    te_log(game, "%s consolidates 3\" after destroying %s in close combat.", winner->name, loser->name);
}

static void resolve_close_combat_outcome(game_t *game, unit_t *attacker, unit_t *target, int attacker_score, int defender_score, follow_up_t follow_up) {
    if (attacker->destroyed || target->destroyed) {
        unit_t *winner = NULL;
        unit_t *loser = NULL;
        if (!attacker->destroyed && target->destroyed) {
            winner = attacker;
            loser = target;
        } else if (attacker->destroyed && !target->destroyed) {
            winner = target;
            loser = attacker;
        }
        clear_locked_state(attacker);
        clear_locked_state(target);
        if (winner != NULL && loser != NULL) {
            consolidate_after_wiping_out_enemy(game, winner, loser);
        }
        return;
    }

    bool won_on_tiebreak = false;
    if (attacker_score == defender_score) {
        int attacker_roll = roll_d6(game);
        int defender_roll = roll_d6(game);
        te_log(game, "Combat tie-break: %s rolls %d, %s rolls %d.", attacker->name, attacker_roll, target->name, defender_roll);
        if (attacker_roll == defender_roll) {
            attacker->locked_in_assault = true;
            attacker->locked_with = target->id;
            target->locked_in_assault = true;
            target->locked_with = attacker->id;
            te_log(game, "The combat remains locked.");
            return;
        }

        won_on_tiebreak = true;
        if (attacker_roll > defender_roll) {
            attacker_score += 1;
        } else {
            defender_score += 1;
        }
    }

    unit_t *winner = attacker_score > defender_score ? attacker : target;
    unit_t *loser = winner == attacker ? target : attacker;
    if (unit_uses_vehicle_rules(loser)) {
        winner->locked_in_assault = true;
        winner->locked_with = loser->id;
        loser->locked_in_assault = true;
        loser->locked_with = winner->id;
        te_log(game, "%s cannot fall back like infantry, so the combat remains locked.", loser->name);
        return;
    }

    int modifier = close_combat_modifier(winner, loser);
    int morale_target = loser->leadership + modifier;
    if (morale_target < 2) {
        morale_target = 2;
    }
    int morale_roll = roll_2d6(game);

    if (morale_roll <= morale_target) {
        te_log(game, "%s holds in close combat on %d against modified Leadership %d.", loser->name, morale_roll, morale_target);
        winner->locked_in_assault = true;
        winner->locked_with = loser->id;
        loser->locked_in_assault = true;
        loser->locked_with = winner->id;
        return;
    }

    te_log(game, "%s loses combat and fails morale on %d against modified Leadership %d.", loser->name, morale_roll, morale_target);
    int fallback_distance = roll_2d6(game);
    resolve_fall_back(game, loser, fallback_distance);

    if (won_on_tiebreak) {
        follow_up = TE_FOLLOW_UP_CONSOLIDATE;
    }

    if (follow_up == TE_FOLLOW_UP_ADVANCE) {
        int advance_distance = roll_2d6(game);
        te_log(game, "%s attempts a sweeping advance of %d\" against %s's %d\" retreat.", winner->name, advance_distance, loser->name, fallback_distance);
        if (advance_distance > fallback_distance && !loser->destroyed) {
            destroy_unit(game, loser, "it was caught in a sweeping advance");
        } else if (!loser->destroyed) {
            float moved = move_toward_point_legally(game, winner, loser->x, loser->y, (float)advance_distance, -1);
            if (moved + 0.01f < (float)advance_distance) {
                te_log(game, "%s advances %.1f\" but stops short of another enemy unit.", winner->name, moved);
            }
        }
    } else {
        float moved = move_toward_point_legally(game, winner, loser->x, loser->y, 3.0f, -1);
        if (moved < 0.01f) {
            te_log(game, "%s cannot consolidate without entering a new combat in the current token model.", winner->name);
        } else if (moved + 0.01f < 3.0f) {
            te_log(game, "%s consolidates %.1f\" after the combat, stopping short of a new combat.", winner->name, moved);
        } else {
            te_log(game, "%s consolidates 3\" after the combat.", winner->name);
        }
    }

    clear_locked_state(winner);
    clear_locked_state(loser);
}

static bool finalize_banded_infantry_close_combat_resolution(
    game_t *game,
    unit_t *attacker,
    unit_t *target,
    int attacker_wounds,
    int defender_wounds,
    follow_up_t follow_up
) {
    if (game == NULL || attacker == NULL || target == NULL) {
        return false;
    }

    if (!attacker->destroyed && attacker->models <= 0) {
        destroy_unit(game, attacker, "it was slain in close combat");
    }
    if (!target->destroyed && target->models <= 0) {
        destroy_unit(game, target, "it was slain in close combat");
    }

    attacker->assaulted_this_turn = true;
    resolve_close_combat_outcome(game, attacker, target, attacker_wounds, defender_wounds, follow_up);
    return true;
}

static bool continue_pending_banded_melee_resolution(game_t *game, int resolved_unsaved_wounds) {
    if (!game_has_pending_banded_melee_resolution(game)) {
        return true;
    }

    int attacker_id = game->pending_banded_melee_attacker_id;
    int target_id = game->pending_banded_melee_target_id;
    follow_up_t follow_up = game->pending_banded_melee_follow_up;
    bool charging = game->pending_banded_melee_charging;
    int next_initiative = game->pending_banded_melee_next_initiative;
    int attacker_wounds = game->pending_banded_melee_attacker_wounds;
    int defender_wounds = game->pending_banded_melee_defender_wounds;
    bool pending_attacker_side = game->pending_banded_melee_pending_attacker_side;
    int resolved_initiative = game->pending_banded_melee_resolved_initiative;
    clear_pending_banded_melee_resolution(game);

    unit_t *attacker = find_unit(game, attacker_id);
    unit_t *target = find_unit(game, target_id);
    if (attacker == NULL || target == NULL) {
        return true;
    }

    if (pending_attacker_side) {
        attacker_wounds += resolved_unsaved_wounds;
        te_log(game, "%s inflicts %d unsaved wound%s in melee at Initiative %d.", attacker->name, resolved_unsaved_wounds, resolved_unsaved_wounds == 1 ? "" : "s", resolved_initiative);
    } else {
        defender_wounds += resolved_unsaved_wounds;
        te_log(game, "%s inflicts %d unsaved wound%s in melee at Initiative %d.", target->name, resolved_unsaved_wounds, resolved_unsaved_wounds == 1 ? "" : "s", resolved_initiative);
    }

    bool paused = resolve_banded_infantry_close_combat(
        game,
        attacker,
        target,
        charging,
        follow_up,
        &attacker_wounds,
        &defender_wounds,
        next_initiative
    );
    if (paused) {
        return true;
    }
    return finalize_banded_infantry_close_combat_resolution(game, attacker, target, attacker_wounds, defender_wounds, follow_up);
}

static bool continue_pending_one_sided_melee_resolution(game_t *game, int resolved_unsaved_wounds) {
    if (!game_has_pending_one_sided_melee_resolution(game)) {
        return true;
    }

    int acting_id = game->pending_one_sided_melee_acting_id;
    int defending_id = game->pending_one_sided_melee_defending_id;
    bool charging = game->pending_one_sided_melee_charging;
    int next_initiative = game->pending_one_sided_melee_next_initiative;
    int accumulated_wounds = game->pending_one_sided_melee_accumulated_wounds + resolved_unsaved_wounds;
    bool counts_for_attacker_score = game->pending_one_sided_melee_counts_for_attacker_score;
    int resolved_initiative = game->pending_one_sided_melee_resolved_initiative;
    pending_one_sided_melee_step_t next_step = game->pending_one_sided_melee_next_step;
    int assault_attacker_id = game->pending_one_sided_melee_assault_attacker_id;
    int assault_target_id = game->pending_one_sided_melee_assault_target_id;
    follow_up_t follow_up = game->pending_one_sided_melee_follow_up;
    int attacker_wounds = game->pending_one_sided_melee_attacker_wounds;
    int defender_wounds = game->pending_one_sided_melee_defender_wounds;
    clear_pending_one_sided_melee_resolution(game);

    unit_t *acting = find_unit(game, acting_id);
    unit_t *defending = find_unit(game, defending_id);
    unit_t *assault_attacker = find_unit(game, assault_attacker_id);
    unit_t *assault_target = find_unit(game, assault_target_id);
    if (acting == NULL || defending == NULL || assault_attacker == NULL || assault_target == NULL) {
        return true;
    }

    te_log(game, "%s inflicts %d unsaved wound%s in melee at Initiative %d.", acting->name, resolved_unsaved_wounds, resolved_unsaved_wounds == 1 ? "" : "s", resolved_initiative);

    int pending_initiative = 0;
    bool paused = resolve_melee_infantry_damage_sequence(
        game,
        acting,
        defending,
        charging,
        true,
        next_initiative,
        &accumulated_wounds,
        &pending_initiative
    );
    if (paused) {
        begin_pending_one_sided_melee_resolution(
            game,
            acting,
            defending,
            charging,
            pending_initiative - 1,
            accumulated_wounds,
            counts_for_attacker_score,
            pending_initiative,
            next_step,
            assault_attacker,
            assault_target,
            follow_up,
            attacker_wounds,
            defender_wounds
        );
        return true;
    }

    if (counts_for_attacker_score) {
        attacker_wounds += accumulated_wounds;
    } else {
        defender_wounds += accumulated_wounds;
    }

    if (next_step == TE_PENDING_ONE_SIDED_MELEE_COVER_ATTACKER_STRIKE) {
        if (!assault_attacker->destroyed && assault_attacker->models <= 0) {
            destroy_unit(game, assault_attacker, "it was cut down during the charge");
        }

        if (!assault_attacker->destroyed && !assault_target->destroyed) {
            int attacker_response_wounds = 0;
            paused = resolve_melee_infantry_damage_sequence(
                game,
                assault_attacker,
                assault_target,
                true,
                true,
                0,
                &attacker_response_wounds,
                &pending_initiative
            );
            if (paused) {
                begin_pending_one_sided_melee_resolution(
                    game,
                    assault_attacker,
                    assault_target,
                    true,
                    pending_initiative - 1,
                    attacker_response_wounds,
                    true,
                    pending_initiative,
                    TE_PENDING_ONE_SIDED_MELEE_FINALIZE_ASSAULT,
                    assault_attacker,
                    assault_target,
                    follow_up,
                    attacker_wounds,
                    defender_wounds
                );
                return true;
            }

            attacker_wounds += attacker_response_wounds;
            te_log(game, "%s inflicts %d unsaved wound%s in melee.", assault_attacker->name, attacker_response_wounds, attacker_response_wounds == 1 ? "" : "s");
        }
    }

    return finalize_banded_infantry_close_combat_resolution(game, assault_attacker, assault_target, attacker_wounds, defender_wounds, follow_up);
}

static bool continue_pending_simultaneous_melee_resolution(game_t *game, int resolved_unsaved_wounds) {
    if (!game_has_pending_simultaneous_melee_resolution(game)) {
        return true;
    }

    int attacker_id = game->pending_simultaneous_melee_attacker_id;
    int target_id = game->pending_simultaneous_melee_target_id;
    follow_up_t follow_up = game->pending_simultaneous_melee_follow_up;
    bool charging = game->pending_simultaneous_melee_charging;
    int resolved_initiative = game->pending_simultaneous_melee_resolved_initiative;
    int next_initiative = game->pending_simultaneous_melee_next_initiative;
    int attacker_wounds = game->pending_simultaneous_melee_attacker_wounds;
    int defender_wounds = game->pending_simultaneous_melee_defender_wounds;
    int band_attacker_wounds = game->pending_simultaneous_melee_band_attacker_wounds;
    int band_defender_wounds = game->pending_simultaneous_melee_band_defender_wounds;
    bool pending_counts_for_attacker_score = game->pending_simultaneous_melee_pending_counts_for_attacker_score;
    pending_simultaneous_melee_step_t step = game->pending_simultaneous_melee_step;
    bool counter_source_valid = game->pending_simultaneous_melee_counter_source_valid;
    unit_t counter_source = game->pending_simultaneous_melee_counter_source;
    clear_pending_simultaneous_melee_resolution(game);

    unit_t *attacker = find_unit(game, attacker_id);
    unit_t *target = find_unit(game, target_id);
    if (attacker == NULL || target == NULL) {
        return true;
    }

    if (pending_counts_for_attacker_score) {
        attacker_wounds += resolved_unsaved_wounds;
        band_attacker_wounds += resolved_unsaved_wounds;
    } else {
        defender_wounds += resolved_unsaved_wounds;
        band_defender_wounds += resolved_unsaved_wounds;
    }

    if (step == TE_PENDING_SIMULTANEOUS_MELEE_RESOLVE_COUNTER) {
        if (!counter_source_valid) {
            return finalize_banded_infantry_close_combat_resolution(game, attacker, target, attacker_wounds, defender_wounds, follow_up);
        }

        int counter_wounds = resolve_melee_infantry_damage_at_initiative(game, &counter_source, attacker, attacker, false, resolved_initiative, true);
        if (game_has_pending_hit_allocation_choice(game)) {
            begin_pending_simultaneous_melee_resolution(
                game,
                attacker,
                target,
                follow_up,
                charging,
                resolved_initiative,
                next_initiative,
                attacker_wounds,
                defender_wounds,
                band_attacker_wounds,
                band_defender_wounds,
                false,
                TE_PENDING_SIMULTANEOUS_MELEE_CONTINUE_BANDS,
                NULL
            );
            return true;
        }

        defender_wounds += counter_wounds;
        band_defender_wounds += counter_wounds;
    }

    te_log(game, "Initiative %d is simultaneous: %s deals %d wound%s and %s deals %d wound%s.", resolved_initiative, attacker->name, band_attacker_wounds, band_attacker_wounds == 1 ? "" : "s", target->name, band_defender_wounds, band_defender_wounds == 1 ? "" : "s");

    if (next_initiative > 0) {
        bool paused = resolve_banded_infantry_close_combat(
            game,
            attacker,
            target,
            charging,
            follow_up,
            &attacker_wounds,
            &defender_wounds,
            next_initiative
        );
        if (paused) {
            return true;
        }
    }

    return finalize_banded_infantry_close_combat_resolution(game, attacker, target, attacker_wounds, defender_wounds, follow_up);
}

bool game_assault_unit(game_t *game, int attacker_id, int target_id, follow_up_t follow_up) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *attacker = find_unit(game, attacker_id);
    unit_t *target = find_unit(game, target_id);

    if (!assert_valid_unit_action(game, attacker)) {
        return false;
    }
    if (target == NULL || target->destroyed) {
        return fail(game, "Target is not available.");
    }
    if (game->phase != TE_PHASE_ASSAULT) {
        return fail(game, "Assaults can only be resolved in the assault phase.");
    }
    if (attacker->kind == TE_UNIT_VEHICLE) {
        return fail(game, "Only assault guns and tank destroyers can launch vehicle assaults.");
    }
    if (attacker->assaulted_this_turn) {
        return fail(game, "%s has already fought an assault this turn.", attacker->name);
    }
    if (attacker->fired_stationary_rapid_or_heavy) {
        return fail(game, "%s cannot assault after standing still to fire rapid-fire or heavy weapons.", attacker->name);
    }
    if (target->owner == attacker->owner) {
        return fail(game, "Units cannot assault their own side.");
    }

    bool assault_gun_combat = attacker->kind == TE_UNIT_ASSAULT_GUN || target->kind == TE_UNIT_ASSAULT_GUN;
    bool vehicle_target = unit_uses_vehicle_rules(target) && target->kind != TE_UNIT_ASSAULT_GUN;
    bool continuing_combat = assault_gun_combat && attacker->locked_in_assault && attacker->locked_with == target->id && target->locked_with == attacker->id;
    bool attacker_stunned_assault_gun = unit_is_crew_stunned_assault_gun(attacker);
    bool target_stunned_assault_gun = unit_is_crew_stunned_assault_gun(target);
    if (attacker->kind == TE_UNIT_ASSAULT_GUN && attacker->immobilized && !continuing_combat) {
        return fail(game, "%s is immobilized and cannot charge into combat.", attacker->name);
    }
    if (attacker_stunned_assault_gun) {
        if (!continuing_combat) {
            return fail(game, "%s is crew stunned and cannot fight in close combat this turn.", attacker->name);
        }
        log_stunned_assault_gun_close_combat_skip(game, attacker);
    }

    float assault_origin_x = attacker->x;
    float assault_origin_y = attacker->y;
    if (!continuing_combat) {
        float range = te_distance(attacker->x, attacker->y, target->x, target->y) - attacker->footprint_radius - target->footprint_radius;
        bool difficult = path_touches_terrain(game, attacker->x, attacker->y, target->x, target->y, TE_TERRAIN_DIFFICULT);
        int assault_distance = difficult ? roll_highest_of_2d6(game) : 6;
        if (range > (float)assault_distance + 0.01f) {
            return fail(game, "%s needs %.1f\" to make contact but only has %d\".", attacker->name, range, assault_distance);
        }

        float contact_distance = fmaxf(range, 0.0f);
        float origin_x = attacker->x;
        float origin_y = attacker->y;
        float moved = move_toward_point_legally(game, attacker, target->x, target->y, contact_distance, target->id);
        if (moved + 0.01f < contact_distance) {
            attacker->x = origin_x;
            attacker->y = origin_y;
            return fail(game, "%s cannot find a legal way to contact %s without entering another combat.", attacker->name, target->name);
        }
        te_log(game, "%s charges into combat with %s.", attacker->name, target->name);
    } else {
        te_log(game, "%s and %s continue their close combat.", attacker->name, target->name);
    }

    if (vehicle_target) {
        int attacker_score = melee_vehicle_damage_results(game, attacker, target, !continuing_combat, assault_origin_x, assault_origin_y);
        attacker->assaulted_this_turn = true;
        clear_locked_state(attacker);
        clear_locked_state(target);

        if (!target->destroyed) {
            te_log(game, "%s remains functional after the assault; vehicle combats do not stay locked in this ruleset.", target->name);
        }
        if (attacker_score <= 0 && !target->destroyed) {
            te_log(game, "%s fails to find a weak point on %s.", attacker->name, target->name);
        }
        return true;
    }

    bool defender_in_cover = cover_save_for_unit(game, target) > 0 && !continuing_combat;
    int attacker_wounds = 0;
    int defender_wounds = 0;
    bool defender_struck_from_cover = false;

    if (defender_in_cover) {
        defender_struck_from_cover = true;
        if (attacker->kind == TE_UNIT_ASSAULT_GUN) {
            defender_wounds = melee_vehicle_damage_results(game, target, attacker, false, target->x, target->y);
        } else if (target_stunned_assault_gun) {
            log_stunned_assault_gun_close_combat_skip(game, target);
        } else {
            int pending_initiative = 0;
            bool paused = resolve_melee_infantry_damage_sequence(
                game,
                target,
                attacker,
                false,
                true,
                0,
                &defender_wounds,
                &pending_initiative
            );
            if (paused) {
                begin_pending_one_sided_melee_resolution(
                    game,
                    target,
                    attacker,
                    false,
                    pending_initiative - 1,
                    defender_wounds,
                    false,
                    pending_initiative,
                    TE_PENDING_ONE_SIDED_MELEE_COVER_ATTACKER_STRIKE,
                    attacker,
                    target,
                    follow_up,
                    attacker_wounds,
                    0
                );
                return true;
            }
            te_log(game, "%s strikes first from cover and inflicts %d unsaved wound%s.", target->name, defender_wounds, defender_wounds == 1 ? "" : "s");
            if (attacker->models <= 0) {
                destroy_unit(game, attacker, "it was cut down during the charge");
            }
        }
    }

    if (!attacker->destroyed && !target->destroyed) {
        if (defender_struck_from_cover) {
            if (attacker_stunned_assault_gun) {
                attacker_wounds = 0;
            } else if (target->kind == TE_UNIT_ASSAULT_GUN) {
                attacker_wounds = melee_vehicle_damage_results(game, attacker, target, !continuing_combat, assault_origin_x, assault_origin_y);
            } else {
                int pending_initiative = 0;
                bool paused = resolve_melee_infantry_damage_sequence(
                    game,
                    attacker,
                    target,
                    !continuing_combat,
                    true,
                    0,
                    &attacker_wounds,
                    &pending_initiative
                );
                if (paused) {
                    begin_pending_one_sided_melee_resolution(
                        game,
                        attacker,
                        target,
                        !continuing_combat,
                        pending_initiative - 1,
                        attacker_wounds,
                        true,
                        pending_initiative,
                    TE_PENDING_ONE_SIDED_MELEE_FINALIZE_ASSAULT,
                    attacker,
                    target,
                    follow_up,
                    0,
                    defender_wounds
                );
                return true;
            }
                te_log(game, "%s inflicts %d unsaved wound%s in melee.", attacker->name, attacker_wounds, attacker_wounds == 1 ? "" : "s");
            }
        } else if (attacker->kind != TE_UNIT_ASSAULT_GUN && target->kind != TE_UNIT_ASSAULT_GUN) {
            bool paused = resolve_banded_infantry_close_combat(game, attacker, target, !continuing_combat, follow_up, &attacker_wounds, &defender_wounds, 0);
            if (paused) {
                return true;
            }
        } else if (attacker->initiative > target->initiative) {
            if (attacker_stunned_assault_gun) {
                attacker_wounds = 0;
            } else if (target->kind == TE_UNIT_ASSAULT_GUN) {
                attacker_wounds = melee_vehicle_damage_results(game, attacker, target, !continuing_combat, assault_origin_x, assault_origin_y);
            } else {
                attacker_wounds = resolve_melee_infantry_damage(game, attacker, target, !continuing_combat);
                te_log(game, "%s inflicts %d unsaved wound%s in melee.", attacker->name, attacker_wounds, attacker_wounds == 1 ? "" : "s");
            }

            if (!target->destroyed) {
                if (target_stunned_assault_gun) {
                    log_stunned_assault_gun_close_combat_skip(game, target);
                } else if (attacker->kind == TE_UNIT_ASSAULT_GUN) {
                    defender_wounds += melee_vehicle_damage_results(game, target, attacker, false, target->x, target->y);
                } else {
                    int counter_wounds = resolve_melee_infantry_damage(game, target, attacker, false);
                    defender_wounds += counter_wounds;
                    te_log(game, "%s inflicts %d unsaved wound%s in melee.", target->name, counter_wounds, counter_wounds == 1 ? "" : "s");
                }
            }
        } else if (target->initiative > attacker->initiative) {
            if (target_stunned_assault_gun) {
                log_stunned_assault_gun_close_combat_skip(game, target);
            } else if (attacker->kind == TE_UNIT_ASSAULT_GUN) {
                defender_wounds += melee_vehicle_damage_results(game, target, attacker, false, target->x, target->y);
            } else {
                int counter_wounds = resolve_melee_infantry_damage(game, target, attacker, false);
                defender_wounds += counter_wounds;
                te_log(game, "%s inflicts %d unsaved wound%s in melee.", target->name, counter_wounds, counter_wounds == 1 ? "" : "s");
            }

            if (!attacker->destroyed) {
                if (attacker_stunned_assault_gun) {
                    attacker_wounds = 0;
                } else if (target->kind == TE_UNIT_ASSAULT_GUN) {
                    attacker_wounds = melee_vehicle_damage_results(game, attacker, target, !continuing_combat, assault_origin_x, assault_origin_y);
                } else {
                    attacker_wounds = resolve_melee_infantry_damage(game, attacker, target, !continuing_combat);
                    te_log(game, "%s inflicts %d unsaved wound%s in melee.", attacker->name, attacker_wounds, attacker_wounds == 1 ? "" : "s");
                }
            }
        } else {
            int simultaneous_attacker_wounds = attacker_wounds;
            int simultaneous_defender_wounds = defender_wounds;
            if (attacker_stunned_assault_gun) {
                attacker_wounds = 0;
            } else if (target->kind == TE_UNIT_ASSAULT_GUN) {
                attacker_wounds = melee_vehicle_damage_results(game, attacker, target, !continuing_combat, assault_origin_x, assault_origin_y);
            } else {
                attacker_wounds = resolve_melee_infantry_damage(game, attacker, target, !continuing_combat);
                simultaneous_attacker_wounds = attacker_wounds;
            }

            if (target_stunned_assault_gun) {
                log_stunned_assault_gun_close_combat_skip(game, target);
            } else if (attacker->kind == TE_UNIT_ASSAULT_GUN) {
                defender_wounds += melee_vehicle_damage_results(game, target, attacker, false, target->x, target->y);
            } else {
                simultaneous_defender_wounds = resolve_melee_infantry_damage(game, target, attacker, false);
                defender_wounds += simultaneous_defender_wounds;
            }

            te_log(game, "The combat is simultaneous: %s deals %d wound%s and %s deals %d wound%s.", attacker->name, attacker_wounds, attacker_wounds == 1 ? "" : "s", target->name, defender_wounds, defender_wounds == 1 ? "" : "s");
        }
    }

    if (!attacker->destroyed && attacker->models <= 0) {
        destroy_unit(game, attacker, "it was slain in close combat");
    }
    if (!target->destroyed && target->models <= 0) {
        destroy_unit(game, target, "it was slain in close combat");
    }

    attacker->assaulted_this_turn = true;
    resolve_close_combat_outcome(game, attacker, target, attacker_wounds, defender_wounds, follow_up);
    return true;
}

bool game_choose_pending_weapon_destroy(game_t *game, int weapon_index) {
    clear_error(game);
    if (!game_has_pending_weapon_destroy_choice(game)) {
        return fail(game, "There is no pending weapon-destroyed choice to resolve.");
    }

    unit_t *target = find_unit(game, game->pending_weapon_destroy_target_id);
    const unit_t *chooser = find_unit_const(game, game->pending_weapon_destroy_chooser_id);
    if (target == NULL || target->destroyed) {
        clear_pending_weapon_destroy_choice(game);
        clear_pending_vehicle_shot_sequence(game);
        return fail(game, "The pending vehicle is no longer available.");
    }

    bool found_option = false;
    for (int index = 0; index < game->pending_weapon_destroy_option_count; index += 1) {
        if (game->pending_weapon_destroy_option_indices[index] == weapon_index) {
            found_option = true;
            break;
        }
    }
    if (!found_option) {
        return fail(game, "That weapon is not available for the pending Weapon Destroyed result.");
    }
    if (weapon_index < 0 || weapon_index >= target->weapon_count || target->weapons[weapon_index].destroyed) {
        return fail(game, "That weapon can no longer be destroyed.");
    }

    clear_pending_weapon_destroy_choice(game);
    destroy_vehicle_weapon_by_choice(game, chooser, target, weapon_index, false);
    if (game_has_pending_vehicle_shot_sequence(game)) {
        return continue_pending_vehicle_shot_sequence(game);
    }
    return true;
}

bool game_choose_pending_hit_allocation(game_t *game, int group_index) {
    clear_error(game);
    if (!game_has_pending_hit_allocation_choice(game)) {
        return fail(game, "There is no pending mixed-profile hit allocation to resolve.");
    }

    unit_t *target = find_unit(game, game->pending_hit_allocation_target_id);
    if (target == NULL || target->destroyed) {
        clear_pending_hit_allocation_choice(game);
        clear_pending_banded_melee_resolution(game);
        clear_pending_one_sided_melee_resolution(game);
        clear_pending_vehicle_shot_sequence(game);
        return fail(game, "The mixed-profile target is no longer available.");
    }
    if (!unit_has_profile_groups(target) || group_index < 0 || group_index >= target->profile_group_count) {
        return fail(game, "That mixed-profile group is not available.");
    }
    if (!pending_hit_allocation_group_can_accept(target, game->pending_hit_allocation_allocated_hits, group_index)) {
        return fail(game, "That group cannot take another hit until the other eligible models have been assigned this round.");
    }

    profile_group_t *group = &target->profile_groups[group_index];
    game->pending_hit_allocation_allocated_hits[group_index] += 1;
    game->pending_hit_allocation_hits_remaining -= 1;

    int assigned = game->pending_hit_allocation_total_hits - game->pending_hit_allocation_hits_remaining;
    te_log(game, "%s assigns hit %d of %d from %s's %s to %s in %s.", player_name(target->owner), assigned, game->pending_hit_allocation_total_hits, game->pending_hit_allocation_attacker_name, game->pending_hit_allocation_source_name, group->name, target->name);

    if (game->pending_hit_allocation_hits_remaining > 0) {
        return true;
    }
    bool continue_vehicle_fire = game_has_pending_vehicle_shot_sequence(game);
    bool continue_banded_melee = game_has_pending_banded_melee_resolution(game);
    bool continue_one_sided_melee = game_has_pending_one_sided_melee_resolution(game);
    bool continue_simultaneous_melee = game_has_pending_simultaneous_melee_resolution(game);
    int resolved_unsaved_wounds = 0;
    if (!finalize_pending_hit_allocation_choice(game, !continue_vehicle_fire && !continue_banded_melee && !continue_one_sided_melee && !continue_simultaneous_melee, &resolved_unsaved_wounds)) {
        return false;
    }
    if (continue_vehicle_fire) {
        return continue_pending_vehicle_shot_sequence(game);
    }
    if (continue_banded_melee) {
        return continue_pending_banded_melee_resolution(game, resolved_unsaved_wounds);
    }
    if (continue_one_sided_melee) {
        return continue_pending_one_sided_melee_resolution(game, resolved_unsaved_wounds);
    }
    if (continue_simultaneous_melee) {
        return continue_pending_simultaneous_melee_resolution(game, resolved_unsaved_wounds);
    }
    return true;
}

bool game_set_preferred_casualty_group(game_t *game, int unit_id, int group_index) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }

    unit_t *unit = find_unit(game, unit_id);
    if (unit == NULL) {
        return fail(game, "Unit not found.");
    }
    if (!unit_has_profile_groups(unit)) {
        return fail(game, "%s does not use mixed profile groups.", unit->name);
    }

    if (group_index < 0) {
        unit->preferred_casualty_group_index = -1;
        te_log(game, "%s returns to automatic mixed-profile casualty allocation.", unit->name);
        return true;
    }

    if (group_index >= unit->profile_group_count || unit->profile_groups[group_index].models <= 0) {
        return fail(game, "That casualty group is not available.");
    }

    unit->preferred_casualty_group_index = group_index;
    te_log(game, "%s will assign mixed-profile casualties to %s first when possible.", unit->name, unit->profile_groups[group_index].name);
    return true;
}

bool game_toggle_cover(game_t *game, int unit_id, bool in_cover) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *unit = find_unit(game, unit_id);
    if (unit == NULL) {
        return fail(game, "Unit not found.");
    }
    unit->manual_in_cover = in_cover;
    te_log(game, "%s %s manual cover.", unit->name, in_cover ? "gains" : "loses");
    return true;
}

bool game_toggle_hull_down(game_t *game, int unit_id, bool hull_down) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *unit = find_unit(game, unit_id);
    if (unit == NULL) {
        return fail(game, "Unit not found.");
    }
    unit->manual_hull_down = hull_down;
    te_log(game, "%s %s hull-down status.", unit->name, hull_down ? "gains" : "loses");
    return true;
}

bool game_use_smoke(game_t *game, int unit_id) {
    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return false;
    }
    unit_t *unit = find_unit(game, unit_id);
    if (!assert_valid_unit_action(game, unit)) {
        return false;
    }
    if (game->phase != TE_PHASE_MOVEMENT) {
        return fail(game, "Smoke launchers can only be used in the movement phase.");
    }
    if (unit->kind != TE_UNIT_VEHICLE) {
        return fail(game, "Only vehicles use smoke launchers.");
    }
    if (!unit->smoke_available) {
        return fail(game, "%s has already used its smoke launchers.", unit->name);
    }

    unit->smoke_available = false;
    unit->smoke_active = true;
    unit->smoke_used_this_turn = true;
    te_log(game, "%s pops smoke and cannot fire this turn.", unit->name);
    return true;
}

void game_advance_phase(game_t *game) {
    if (game == NULL) {
        return;
    }

    clear_error(game);
    if (!assert_no_pending_resolution_choice(game)) {
        return;
    }

    if (game->phase == TE_PHASE_MOVEMENT) {
        game->phase = TE_PHASE_SHOOTING;
        init_shooting_phase(game);
        te_log(game, "%s advances to the %s phase.", player_name(game->active_player), phase_name(game->phase));
        return;
    }

    if (game->phase == TE_PHASE_SHOOTING) {
        game->phase = TE_PHASE_ASSAULT;
        te_log(game, "%s advances to the %s phase.", player_name(game->active_player), phase_name(game->phase));
        return;
    }

    finish_turn(game, game->active_player);
    score_objectives(game);
    game->active_player = other_player(game->active_player);
    game->phase = TE_PHASE_MOVEMENT;
    game->turn_number += 1;
    begin_turn(game);
}
