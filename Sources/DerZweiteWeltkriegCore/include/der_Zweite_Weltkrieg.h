#ifndef DER_ZWEITE_WELTKRIEG_H
#define DER_ZWEITE_WELTKRIEG_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct te_game game_t;

typedef enum {
    TE_PLAYER_NONE = 0,
    TE_PLAYER_ONE = 1,
    TE_PLAYER_TWO = 2
} player_t;

typedef enum {
    TE_PHASE_MOVEMENT = 0,
    TE_PHASE_SHOOTING = 1,
    TE_PHASE_ASSAULT = 2
} phase_t;

typedef enum {
    TE_UNIT_INFANTRY = 0,
    TE_UNIT_VEHICLE = 1,
    TE_UNIT_ASSAULT_GUN = 2
} unit_kind_t;

typedef enum {
    TE_TERRAIN_OPEN = 0,
    TE_TERRAIN_DIFFICULT = 1,
    TE_TERRAIN_IMPASSABLE = 2
} terrain_kind_t;

typedef enum {
    TE_FOLLOW_UP_ADVANCE = 0,
    TE_FOLLOW_UP_CONSOLIDATE = 1
} follow_up_t;

typedef enum {
    TE_ARMY_DEMO = 0,
    TE_ARMY_BRITISH = 1,
    TE_ARMY_AMERICAN = 2,
    TE_ARMY_AUSTRALIAN = 3,
    TE_ARMY_SOVIET = 4,
    TE_ARMY_GERMAN = 5,
    TE_ARMY_ITALIAN = 6
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
    int range;
    int strength;
    int ap;
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
    int turn_number;
    player_t active_player;
    phase_t phase;
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
    bool can_move_now;
    bool shot_this_turn;
    bool assaulted_this_turn;
    bool can_shoot_now;
    bool can_assault_now;
    bool locked_in_assault;
    bool pinned;
    bool falling_back;
    bool embarked;
    int embarked_unit_id;
    int embarked_in_transport_id;
    int transport_capacity;
    bool destroyed;
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
