#ifndef DER_ZWEITE_WELTKRIEG_H
#define DER_ZWEITE_WELTKRIEG_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct dzw_game game_t;

typedef enum {
    DZW_PLAYER_NONE = 0,
    DZW_PLAYER_ONE = 1,
    DZW_PLAYER_TWO = 2
} player_t;

typedef enum {
    DZW_PHASE_MOVEMENT = 0,
    DZW_PHASE_SHOOTING = 1,
    DZW_PHASE_ASSAULT = 2
} phase_t;

typedef enum {
    DZW_RULESET_FIXED_PHASES = 0,
    DZW_RULESET_ORDER_DICE = 1
} dzw_ruleset_t;

typedef enum {
    DZW_ORDER_NONE = 0,
    DZW_ORDER_FIRE = 1,
    DZW_ORDER_ADVANCE = 2,
    DZW_ORDER_RUN = 3,
    DZW_ORDER_AMBUSH = 4,
    DZW_ORDER_RALLY = 5,
    DZW_ORDER_DOWN = 6
} dzw_order_t;

typedef enum {
    DZW_MORALE_REGULAR = 0,
    DZW_MORALE_INEXPERIENCED = 1,
    DZW_MORALE_VETERAN = 2
} dzw_morale_quality_t;

typedef enum {
    DZW_ORDER_TEST_NOT_REQUIRED = 0,
    DZW_ORDER_TEST_PASSED = 1,
    DZW_ORDER_TEST_FAILED = 2,
    DZW_ORDER_TEST_FUBAR = 3
} dzw_order_test_result_t;

typedef enum {
    DZW_FUBAR_NONE = 0,
    DZW_FUBAR_FRIENDLY_FIRE = 1,
    DZW_FUBAR_PANIC = 2,
    DZW_FUBAR_DOWN = 3
} dzw_fubar_result_t;

typedef enum {
    DZW_TARGET_REACTION_NONE = 0,
    DZW_TARGET_REACTION_DOWN = 1,
    DZW_TARGET_REACTION_AMBUSH_READY = 2
} dzw_target_reaction_t;

typedef enum {
    DZW_VEHICLE_DAMAGE_NONE = 0,
    DZW_VEHICLE_DAMAGE_SUPERFICIAL = 1,
    DZW_VEHICLE_DAMAGE_FULL = 2,
    DZW_VEHICLE_DAMAGE_MASSIVE = 3
} dzw_vehicle_damage_class_t;

typedef enum {
    DZW_VEHICLE_DAMAGE_RESULT_NONE = 0,
    DZW_VEHICLE_DAMAGE_RESULT_CREW_STUNNED = 1,
    DZW_VEHICLE_DAMAGE_RESULT_IMMOBILIZED = 2,
    DZW_VEHICLE_DAMAGE_RESULT_ON_FIRE = 3,
    DZW_VEHICLE_DAMAGE_RESULT_KNOCKED_OUT = 4
} dzw_vehicle_damage_result_t;

typedef enum {
    DZW_UNIT_INFANTRY = 0,
    DZW_UNIT_VEHICLE = 1,
    DZW_UNIT_ASSAULT_GUN = 2
} unit_kind_t;

typedef enum {
    DZW_TERRAIN_OPEN = 0,
    DZW_TERRAIN_DIFFICULT = 1,
    DZW_TERRAIN_ROUGH = 1,
    DZW_TERRAIN_IMPASSABLE = 2,
    DZW_TERRAIN_OBSTACLE = 3,
    DZW_TERRAIN_BUILDING = 4,
    DZW_TERRAIN_ROAD = 5
} terrain_kind_t;

typedef enum {
    DZW_FOLLOW_UP_ADVANCE = 0,
    DZW_FOLLOW_UP_CONSOLIDATE = 1
} follow_up_t;

typedef enum {
    DZW_ARMY_DEMO = 0,
    DZW_ARMY_BRITISH = 1,
    DZW_ARMY_AMERICAN = 2,
    DZW_ARMY_AUSTRALIAN = 3,
    DZW_ARMY_SOVIET = 4,
    DZW_ARMY_GERMAN = 5,
    DZW_ARMY_ITALIAN = 6
} army_list_t;

typedef struct {
    float x;
    float y;
    float width;
    float height;
} rect_t;

typedef struct {
    int id;
    const char *name;
    terrain_kind_t kind;
    rect_t rect;
    int cover_save;
    bool blocks_line_of_sight;
    bool hull_down;
} zone_view_t;

typedef struct {
    const char *name;
    int target_score;
    int player_one_score;
    int player_two_score;
    player_t winner;
} mission_view_t;

typedef struct {
    int id;
    const char *name;
    float x;
    float y;
    float radius;
    player_t controller;
    int player_one_presence;
    int player_two_presence;
} objective_view_t;

typedef struct {
    const char *name;
    unit_kind_t kind;
    int models;
    int wounds_per_model;
    int total_wounds;
    bool mixed_profiles;
    int transport_capacity;
    int front_armour;
    int side_armour;
    int rear_armour;
    bool fast;
    bool recon;
    bool open_topped;
    const char *primary_weapon_name;
    const char *embarked_unit_name;
    const char *embarked_transport_name;
} army_roster_unit_view_t;

typedef struct {
    int id;
    const char *name;
    const char *summary;
} army_force_view_t;

typedef struct {
    int catalog_id;
    const char *name;
    int points;
    int max_count;
    army_roster_unit_view_t unit;
    const char *source_note;
} army_catalog_unit_view_t;

typedef struct {
    const char *name;
    int min_range;
    int range;
    int strength;
    int ap;
    int penetration;
    int shots;
    bool rapid_fire;
    bool pistol;
    bool assault;
    bool heavy;
    bool flame;
    bool ignores_cover;
    bool ordnance;
    bool barrage;
    int blast_diameter;
    int he_hits_dice_count;
    int he_hits_die_sides;
    int he_pins_dice_count;
    int he_pins_die_sides;
    int he_penetration;
    bool indirect_fire;
    bool team;
    bool fixed;
    bool shaped_charge;
    bool one_shot;
} weapon_profile_view_t;

typedef struct {
    int catalog_id;
    int count;
} army_list_entry_t;

typedef struct {
    int id;
    const char *name;
    terrain_kind_t kind;
    rect_t rect;
    int cover_save;
    bool blocks_line_of_sight;
    bool hull_down;
} guderian_scenario_zone_t;

typedef struct {
    int id;
    const char *name;
    float x;
    float y;
    float radius;
} guderian_scenario_objective_t;

typedef struct {
    bool active;
    int chooser_id;
    player_t chooser_owner;
    const char *chooser_name;
    int target_id;
    const char *target_name;
} pending_weapon_destroy_view_t;

typedef struct {
    int weapon_index;
    const char *name;
} vehicle_weapon_view_t;

typedef struct {
    bool active;
    player_t chooser_owner;
    const char *attacker_name;
    const char *source_name;
    int target_id;
    const char *target_name;
    int hits_assigned;
    int hits_remaining;
    int total_hits;
} pending_hit_allocation_view_t;

typedef struct {
    int index;
    const char *name;
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
    bool preferred_casualty_group;
    int pending_allocated_hits;
} profile_group_view_t;

typedef struct {
    bool available;
    int sequence;
    player_t owner;
} order_die_view_t;

typedef struct {
    int unit_id;
    dzw_order_t order;
    bool eligible;
    bool requires_order_test;
    const char *reason;
} unit_order_eligibility_view_t;

typedef struct {
    int turn_number;
    player_t active_player;
    phase_t phase;
    dzw_ruleset_t ruleset;
} game_view_t;

typedef struct {
    int id;
    const char *name;
    player_t owner;
    unit_kind_t kind;
    float x;
    float y;
    float facing_degrees;
    float footprint_radius;
    int models;
    int wounds_per_model;
    int lead_model_wounds;
    int total_wounds_remaining;
    bool mixed_profiles;
    int starting_models;
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
    bool in_cover;
    bool hull_down;
    bool smoke_available;
    bool smoke_active;
    bool moved_this_turn;
    float moved_distance;
    bool can_move_now;
    bool shot_this_turn;
    bool assaulted_this_turn;
    bool can_shoot_now;
    bool can_assault_now;
    bool locked_in_assault;
    bool pinned;
    bool falling_back;
    dzw_order_t current_order;
    bool acted_this_turn;
    bool retained_order;
    int pin_count;
    dzw_morale_quality_t morale_quality;
    dzw_order_test_result_t last_order_test_result;
    int last_order_test_roll;
    int last_order_test_target;
    int last_order_test_pin_modifier;
    int last_order_test_officer_modifier;
    dzw_fubar_result_t last_fubar_result;
    int last_fubar_target_id;
    bool down_order_active;
    bool ambush_order_active;
    int defensive_to_hit_modifier;
    int last_rally_roll;
    int last_rally_pins_removed;
    float advance_move_allowance;
    float run_move_allowance;
    float assault_move_allowance;
    float current_order_move_allowance;
    float reverse_move_allowance;
    bool can_reverse_now;
    int pivot_budget;
    int pivot_count_used;
    float last_reverse_distance;
    const char *movement_rejection_reason;
    int last_shooting_target_id;
    float last_shooting_range;
    dzw_target_reaction_t last_shooting_target_reaction;
    bool last_shooting_range_checked;
    bool last_shooting_hit_rolls_resolved;
    bool last_shooting_damage_resolved;
    int last_shooting_base_to_hit;
    int last_shooting_point_blank_modifier;
    int last_shooting_pin_modifier;
    int last_shooting_long_range_modifier;
    int last_shooting_inexperienced_modifier;
    int last_shooting_move_modifier;
    int last_shooting_down_modifier;
    int last_shooting_small_unit_modifier;
    int last_shooting_cover_modifier;
    int last_shooting_to_hit_modifier;
    int last_shooting_needed_to_hit;
    int last_shooting_damage_value;
    int last_shooting_penetration_modifier;
    int last_shooting_damage_roll;
    bool last_shooting_damage_success;
    int last_shooting_vehicle_armour_modifier;
    int last_shooting_vehicle_long_range_penalty;
    int last_shooting_vehicle_open_topped_indirect_modifier;
    dzw_vehicle_damage_class_t last_shooting_vehicle_damage_class;
    int last_vehicle_damage_table_roll;
    dzw_vehicle_damage_result_t last_vehicle_damage_result;
    int last_vehicle_damage_morale_roll;
    int last_vehicle_damage_morale_target;
    bool last_vehicle_damage_morale_failed;
    int last_shooting_models_removed;
    int last_shooting_pins_added;
    bool last_shooting_morale_checked;
    int last_shooting_morale_roll;
    int last_shooting_morale_target;
    int last_shooting_morale_pin_modifier;
    int last_shooting_morale_officer_modifier;
    bool last_shooting_morale_failed;
    bool embarked;
    int embarked_unit_id;
    int embarked_in_transport_id;
    int transport_capacity;
    bool destroyed;
    bool wrecked;
    bool wreck_blocks_movement;
    int last_assault_target_id;
    float last_assault_range;
    dzw_target_reaction_t last_assault_target_reaction;
    int last_assault_attacker_wounds;
    int last_assault_defender_wounds;
    int last_assault_draw_rounds;
    int last_assault_winner_id;
    int last_assault_loser_id;
    bool last_assault_loser_destroyed;
    float last_assault_regroup_distance;
} unit_view_t;

float game_board_width(void);
float game_board_height(void);
game_t *game_create_demo(uint32_t seed);
game_t *game_create_demo_with_armies(uint32_t seed, army_list_t player_one_army, army_list_t player_two_army);
game_t *game_create_demo_with_forces(uint32_t seed, army_list_t player_one_army, int player_one_force, army_list_t player_two_army, int player_two_force);
game_t *game_create_skirmish(uint32_t seed, army_list_t player_one_army, const army_list_entry_t *player_one_entries, int player_one_entry_count, army_list_t player_two_army, const army_list_entry_t *player_two_entries, int player_two_entry_count);
bool game_apply_guderian_scenario_board(game_t *game, const char *mission_name, int target_score, const guderian_scenario_zone_t *zones, int zone_count, const guderian_scenario_objective_t *objectives, int objective_count);
void game_destroy(game_t *game);
void game_reset_demo(game_t *game, uint32_t seed);
void game_reset_demo_with_armies(game_t *game, uint32_t seed, army_list_t player_one_army, army_list_t player_two_army);
void game_reset_demo_with_forces(game_t *game, uint32_t seed, army_list_t player_one_army, int player_one_force, army_list_t player_two_army, int player_two_force);
void game_reset_skirmish(game_t *game, uint32_t seed, army_list_t player_one_army, const army_list_entry_t *player_one_entries, int player_one_entry_count, army_list_t player_two_army, const army_list_entry_t *player_two_entries, int player_two_entry_count);
void game_seed(game_t *game, uint32_t seed);
army_list_t game_player_army(const game_t *game, player_t player);
int game_player_force(const game_t *game, player_t player);
const char *army_name(army_list_t army);
int army_force_count(army_list_t army);
army_force_view_t army_force_view(army_list_t army, int index);
int army_roster_unit_count(army_list_t army);
army_roster_unit_view_t army_roster_unit_view(army_list_t army, int index);
int army_force_roster_unit_count(army_list_t army, int force_index);
army_roster_unit_view_t army_force_roster_unit_view(army_list_t army, int force_index, int index);
int army_catalog_unit_count(army_list_t army);
army_catalog_unit_view_t army_catalog_unit_view(army_list_t army, int index);
int army_list_total_points(army_list_t army, const army_list_entry_t *entries, int entry_count);
int wwii_weapon_profile_count(void);
weapon_profile_view_t wwii_weapon_profile_view(int index);

dzw_ruleset_t game_ruleset(const game_t *game);
bool game_set_ruleset(game_t *game, dzw_ruleset_t ruleset);
const char *game_ruleset_name(dzw_ruleset_t ruleset);
const char *game_order_name(dzw_order_t order);
const char *game_morale_quality_name(dzw_morale_quality_t quality);
const char *game_order_test_result_name(dzw_order_test_result_t result);
const char *game_fubar_result_name(dzw_fubar_result_t result);
const char *game_target_reaction_name(dzw_target_reaction_t reaction);
const char *game_vehicle_damage_result_name(dzw_vehicle_damage_result_t result);
bool game_uses_legacy_phase_flow(const game_t *game);
int game_phase_flow_migration_blocker_count(const game_t *game);
const char *game_phase_flow_migration_blocker(const game_t *game, int index);
bool game_rebuild_order_dice_cup(game_t *game);
int game_order_dice_remaining_count(const game_t *game);
order_die_view_t game_order_dice_remaining_view(const game_t *game, int index);
int game_order_dice_spent_count(const game_t *game);
order_die_view_t game_order_dice_spent_view(const game_t *game, int index);
int game_order_dice_retained_count(const game_t *game);
order_die_view_t game_order_dice_retained_view(const game_t *game, int index);
order_die_view_t game_current_order_die_view(const game_t *game);
uint32_t game_order_dice_replay_signature(const game_t *game);
unit_order_eligibility_view_t game_unit_order_eligibility_view(const game_t *game, int unit_id, dzw_order_t order);
bool game_draw_order_die(game_t *game);
bool game_assign_order(game_t *game, int unit_id, dzw_order_t order);
bool game_resolve_order_test(game_t *game, int unit_id);
bool game_resolve_rally_order(game_t *game, int unit_id);
bool game_trigger_ambush_order(game_t *game, int unit_id);
bool game_cancel_ambush_order(game_t *game, int unit_id);
bool game_order_dice_turn_complete(const game_t *game);
bool game_end_order_dice_turn(game_t *game);
float game_unit_order_movement_allowance(const game_t *game, int unit_id, dzw_order_t order);
const char *game_unit_order_movement_rejection_reason(const game_t *game, int unit_id, dzw_order_t order);
int game_fubar_friendly_fire_target_count(const game_t *game, int unit_id);
unit_view_t game_fubar_friendly_fire_target_view(const game_t *game, int unit_id, int index);

game_view_t game_view(const game_t *game);
mission_view_t game_mission_view(const game_t *game);
int game_unit_count(const game_t *game);
unit_view_t game_unit_view(const game_t *game, int index);
int game_zone_count(const game_t *game);
zone_view_t game_zone_view(const game_t *game, int index);
int game_objective_count(const game_t *game);
objective_view_t game_objective_view(const game_t *game, int index);
int game_log_count(const game_t *game);
const char *game_log_line(const game_t *game, int index);
const char *game_last_error(const game_t *game);
pending_weapon_destroy_view_t game_pending_weapon_destroy_view(const game_t *game);
int game_pending_weapon_destroy_option_count(const game_t *game);
vehicle_weapon_view_t game_pending_weapon_destroy_option_view(const game_t *game, int index);
pending_hit_allocation_view_t game_pending_hit_allocation_view(const game_t *game);
int game_unit_profile_group_count(const game_t *game, int unit_id);
profile_group_view_t game_unit_profile_group_view(const game_t *game, int unit_id, int index);

bool game_move_unit(game_t *game, int unit_id, float x, float y);
bool game_reverse_unit(game_t *game, int unit_id, float distance);
bool game_deploy_unit(game_t *game, int unit_id, float x, float y);
bool game_tank_shock_unit(game_t *game, int attacker_id, int target_id);
bool game_embark_unit(game_t *game, int unit_id, int transport_id);
bool game_disembark_unit(game_t *game, int transport_id);
bool game_fire_passenger(game_t *game, int transport_id, int target_id);
bool game_rotate_unit(game_t *game, int unit_id, float facing_degrees);
bool game_deploy_rotate_unit(game_t *game, int unit_id, float facing_degrees);
bool game_shoot_unit(game_t *game, int attacker_id, int target_id);
bool game_assault_unit(game_t *game, int attacker_id, int target_id, follow_up_t follow_up);
bool game_choose_pending_weapon_destroy(game_t *game, int weapon_index);
bool game_choose_pending_hit_allocation(game_t *game, int group_index);
bool game_set_preferred_casualty_group(game_t *game, int unit_id, int group_index);
bool game_toggle_cover(game_t *game, int unit_id, bool in_cover);
bool game_toggle_hull_down(game_t *game, int unit_id, bool hull_down);
bool game_use_smoke(game_t *game, int unit_id);
void game_advance_phase(game_t *game);

#ifdef __cplusplus
}
#endif

#endif
