#include "shared.h"

#include <math.h>
#include <stddef.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static float shared_minf(float a, float b) {
    return a < b ? a : b;
}

static float shared_maxf(float a, float b) {
    return a > b ? a : b;
}

static float shared_cross(shared_point_t a, shared_point_t b, shared_point_t c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

float shared_normalize_angle(float angle) {
    while (angle < 0.0f) {
        angle += 360.0f;
    }
    while (angle >= 360.0f) {
        angle -= 360.0f;
    }
    return angle;
}

float shared_point_distance(shared_point_t a, shared_point_t b) {
    float dx = a.x - b.x;
    float dy = a.y - b.y;
    return sqrtf((dx * dx) + (dy * dy));
}

float shared_angle_to(shared_point_t from, shared_point_t to) {
    return shared_normalize_angle(atan2f(to.y - from.y, to.x - from.x) * (180.0f / (float)M_PI));
}

float shared_smallest_angle_between(float left, float right) {
    float difference = fabsf(shared_normalize_angle(left) - shared_normalize_angle(right));
    return difference > 180.0f ? 360.0f - difference : difference;
}

bool shared_angle_within_arc(float facing_degrees, float target_angle_degrees, float arc_degrees) {
    return shared_smallest_angle_between(facing_degrees, target_angle_degrees) <= arc_degrees * 0.5f + 0.001f;
}

bool shared_point_in_rect(shared_point_t point, shared_rect_t rect) {
    return point.x >= rect.x &&
           point.x <= rect.x + rect.width &&
           point.y >= rect.y &&
           point.y <= rect.y + rect.height;
}

bool shared_on_segment(shared_point_t start, shared_point_t end, shared_point_t point) {
    float min_x = shared_minf(start.x, end.x);
    float max_x = shared_maxf(start.x, end.x);
    float min_y = shared_minf(start.y, end.y);
    float max_y = shared_maxf(start.y, end.y);
    return point.x >= min_x - 0.001f &&
           point.x <= max_x + 0.001f &&
           point.y >= min_y - 0.001f &&
           point.y <= max_y + 0.001f;
}

bool shared_segments_intersect(shared_point_t a, shared_point_t b, shared_point_t c, shared_point_t d) {
    float d1 = shared_cross(a, b, c);
    float d2 = shared_cross(a, b, d);
    float d3 = shared_cross(c, d, a);
    float d4 = shared_cross(c, d, b);

    if (((d1 > 0.0f && d2 < 0.0f) || (d1 < 0.0f && d2 > 0.0f)) &&
        ((d3 > 0.0f && d4 < 0.0f) || (d3 < 0.0f && d4 > 0.0f))) {
        return true;
    }

    if (fabsf(d1) < 0.001f && shared_on_segment(a, b, c)) {
        return true;
    }
    if (fabsf(d2) < 0.001f && shared_on_segment(a, b, d)) {
        return true;
    }
    if (fabsf(d3) < 0.001f && shared_on_segment(c, d, a)) {
        return true;
    }
    if (fabsf(d4) < 0.001f && shared_on_segment(c, d, b)) {
        return true;
    }

    return false;
}

bool shared_segment_intersects_rect(shared_point_t start, shared_point_t end, shared_rect_t rect) {
    if (shared_point_in_rect(start, rect) || shared_point_in_rect(end, rect)) {
        return true;
    }

    shared_point_t a = shared_make_point(rect.x, rect.y);
    shared_point_t b = shared_make_point(rect.x + rect.width, rect.y);
    shared_point_t c = shared_make_point(rect.x + rect.width, rect.y + rect.height);
    shared_point_t d = shared_make_point(rect.x, rect.y + rect.height);

    return shared_segments_intersect(start, end, a, b) ||
           shared_segments_intersect(start, end, b, c) ||
           shared_segments_intersect(start, end, c, d) ||
           shared_segments_intersect(start, end, d, a);
}

int shared_roll_d6(shared_rng_t *rng) {
    return (int)(shared_adapter_next_random(rng) % 6u) + 1;
}

int shared_roll_2d6(shared_rng_t *rng) {
    return shared_roll_d6(rng) + shared_roll_d6(rng);
}

int shared_roll_highest_of_2d6(shared_rng_t *rng) {
    int first = shared_roll_d6(rng);
    int second = shared_roll_d6(rng);
    return first > second ? first : second;
}

int shared_required_to_wound(int strength, int toughness) {
    return shared_adapter_required_to_wound(strength, toughness);
}

void shared_clear_locked_state(shared_game_t *game, shared_unit_t *first, shared_unit_t *second) {
    if (first == NULL && second == NULL) {
        return;
    }
    shared_adapter_clear_locked_state(game, first, second);
}

void shared_destroy_unit(shared_game_t *game, shared_unit_t *unit, const char *reason) {
    if (unit == NULL) {
        return;
    }
    shared_adapter_destroy_unit(game, unit, reason);
}
