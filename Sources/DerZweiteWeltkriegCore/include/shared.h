#ifndef CORE_SHARED_H
#define CORE_SHARED_H

#include <stdbool.h>
#include <stdint.h>

typedef struct shared_point {
    float x;
    float y;
} shared_point_t;

typedef struct shared_rect {
    float x;
    float y;
    float width;
    float height;
} shared_rect_t;

typedef struct shared_rng shared_rng_t;
typedef struct shared_game shared_game_t;
typedef struct shared_unit shared_unit_t;

static inline shared_point_t shared_make_point(float x, float y) {
    shared_point_t point = {
        .x = x,
        .y = y,
    };
    return point;
}

static inline shared_rect_t shared_make_rect(float x, float y, float width, float height) {
    shared_rect_t rect = {
        .x = x,
        .y = y,
        .width = width,
        .height = height,
    };
    return rect;
}

float shared_normalize_angle(float angle);
float shared_point_distance(shared_point_t a, shared_point_t b);
float shared_angle_to(shared_point_t from, shared_point_t to);
float shared_smallest_angle_between(float left, float right);
bool shared_angle_within_arc(float facing_degrees, float target_angle_degrees, float arc_degrees);
bool shared_point_in_rect(shared_point_t point, shared_rect_t rect);
bool shared_on_segment(shared_point_t start, shared_point_t end, shared_point_t point);
bool shared_segments_intersect(shared_point_t a, shared_point_t b, shared_point_t c, shared_point_t d);
bool shared_segment_intersects_rect(shared_point_t start, shared_point_t end, shared_rect_t rect);
int shared_roll_d6(shared_rng_t *rng);
int shared_roll_2d6(shared_rng_t *rng);
int shared_roll_highest_of_2d6(shared_rng_t *rng);
int shared_required_to_wound(int strength, int toughness);
void shared_clear_locked_state(shared_game_t *game, shared_unit_t *first, shared_unit_t *second);
void shared_destroy_unit(shared_game_t *game, shared_unit_t *unit, const char *reason);

uint32_t shared_adapter_next_random(shared_rng_t *rng);
int shared_adapter_required_to_wound(int strength, int toughness);
void shared_adapter_clear_locked_state(shared_game_t *game, shared_unit_t *first, shared_unit_t *second);
void shared_adapter_destroy_unit(shared_game_t *game, shared_unit_t *unit, const char *reason);

#endif
