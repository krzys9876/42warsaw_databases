#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

struct module {
    char display_name[32];
    int id;
};

typedef struct module module_t;

struct part {
    char display_name[32];
    int id;
    char supplier[32];
};

typedef struct part part_t;

#define DECLARE_LIST(T, name)                                                          \
    typedef struct name##_with_quantity {                                              \
        T *item;                                                                       \
        int quantity;                                                                  \
    } name##_with_quantity_t;                                                          \
                                                                                       \
    typedef struct name##_list {                                                       \
        name##_with_quantity_t head;                                                   \
        struct name##_list *tail;                                                      \
    } name##_list_t;                                                                   \
                                                                                       \
    static void name##_list_init(name##_list_t *q) {                                   \
        q->head.item = NULL;                                                           \
        q->head.quantity = 0;                                                          \
        q->tail = NULL;                                                                \
    }                                                                                  \
                                                                                       \
    static int name##_list_is_empty(name##_list_t *q) { return q->head.item == NULL; } \
    static int name##_list_is_last(name##_list_t *q) { return q->tail == NULL; }       \
                                                                                       \
    static void name##_list_push(name##_list_t *q, name##_with_quantity_t *p) {        \
        if (name##_list_is_empty(q)) {                                                 \
            q->head = *p;                                                              \
            return;                                                                    \
        }                                                                              \
                                                                                       \
        name##_list_t *last = q;                                                       \
        while (!name##_list_is_last(last))                                             \
            last = last->tail;                                                         \
        name##_list_t *new_tail = malloc(sizeof(name##_list_t));                       \
        new_tail->head = *p;                                                           \
        new_tail->tail = NULL;                                                         \
        last->tail = new_tail;                                                         \
    }                                                                                  \
                                                                                       \
    static name##_list_t name##_list_make_v(name##_with_quantity_t *first, ...) {      \
        name##_list_t q;                                                               \
        name##_list_init(&q);                                                          \
        if (!first)                                                                    \
            return q;                                                                  \
                                                                                       \
        va_list ap;                                                                    \
        va_start(ap, first);                                                           \
        name##_list_push(&q, first);                                                   \
        for (name##_with_quantity_t *p = va_arg(ap, name##_with_quantity_t *);         \
             p != NULL; p = va_arg(ap, name##_with_quantity_t *))                      \
            name##_list_push(&q, p);                                                   \
        va_end(ap);                                                                    \
        return q;                                                                      \
    }                                                                                  \
                                                                                       \
    static void name##_print_one(name##_with_quantity_t p) {                           \
        printf("%s (%d) ", p.item->display_name, p.quantity);                          \
    }                                                                                  \

DECLARE_LIST(part_t, part)
#define make_part_list(...) part_list_make_v(__VA_ARGS__, (part_with_quantity_t *)NULL)
DECLARE_LIST(module_t, module)
#define make_module_list(...) module_list_make_v(__VA_ARGS__, (module_with_quantity_t *)NULL)

// Types
struct module_with_parts {
    module_t m;
    part_list_t p;
};

typedef struct module_with_parts module_with_parts_t;

struct part_with_modules {
    part_t p;
    module_list_t m;
};

typedef struct part_with_modules part_with_modules_t;

// Traverse and print
// Module with parts
static void traverse_part_list(part_list_t *q) {
    if (part_list_is_empty(q)) return;

    part_list_t *current = q;
    part_print_one(current->head);
    while (!part_list_is_last(current)) {
        current = current->tail;
        part_print_one(current->head);
    }
    printf("\n");
}

static void print_modules(module_with_parts_t modules[], const int cnt) {
    // Traverse and print
    for (int i = 0; i < cnt; i++) {
        printf("module: %s (#%d), parts: ", modules[i].m.display_name, modules[i].m.id);
        traverse_part_list(&modules[i].p);
    }
    printf("\n");
}

// Parts with modules (details)
static void traverse_module_list(module_list_t *q) {
    if (module_list_is_empty(q)) return;

    module_list_t *current = q;
    module_print_one(current->head);
    while (!module_list_is_last(current)) {
        current = current->tail;
        module_print_one(current->head);
    }
    printf("\n");
}

static void print_parts(part_with_modules_t parts[], const int cnt) {
    // Traverse and print
    for (int i = 0; i < cnt; i++) {
        printf("part: %s (%s), modules: ", parts[i].p.display_name, parts[i].p.supplier);
        traverse_module_list(&parts[i].m);
    }
    printf("\n");
}

// Parts with modules (aggregate)
static void aggregate_module_list(module_list_t *q) {
    if (module_list_is_empty(q)) return;

    int quantity = 0;
    module_list_t *current = q;
    quantity+=current->head.quantity;
    while (!module_list_is_last(current)) {
        current = current->tail;
        quantity+=current->head.quantity;
    }
    printf("%d\n", quantity);
}

static void print_parts_agg(part_with_modules_t parts[], const int cnt) {
    // Traverse and print
    for (int i = 0; i < cnt; i++) {
        printf("part: %s (%s), required: ", parts[i].p.display_name, parts[i].p.supplier);
        aggregate_module_list(&parts[i].m);
    }
    printf("\n");
}

// The "database" program
int main(void) {
    // The diagram shows modules and their parts. These are not actual parts (as modules may require more than one), threat them as metadata.
    // Note that some parts linked to more than one module.
    /*
            ┌─────────┐                                 ┌─────────┐
            │ module1 │                                 │ module3 │
            └────┬────┘                                 └────┬────┘
         ┌───────┼───────┐                       ┌───────┬───┴───┬───────┐
         1       3       2                       4       2       1       3
      ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌─────┐ ┌─────┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐ ┌──┴──┐
      │part1│ │part2│ │part3│ │part4│ │part5│ │part6│ │part7│ │part8│ │part9│
      └─────┘ └─────┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └─────┘ └─────┘
                         8       7       4       5       2
                         └───────┴───────┼───────┴───────┘
                                    ┌────┴────┐
                                    │ module2 │
                                    └─────────┘
    */
    module_t modules[] = {
        {.display_name = "module1", .id = 1}, {.display_name = "module2", .id = 2}, {.display_name = "module3", .id = 3}};
    int module_cnt = sizeof(modules) / sizeof(module_t);
    printf("no. of modules: %d\n", module_cnt);
    part_t parts[] = {
        {.display_name = "part1", .id = 1, .supplier = "supplier1"},{.display_name = "part2", .id = 2, .supplier = "supplier1"},{.display_name = "part3", .id = 3, .supplier = "supplier1"},
        {.display_name = "part4", .id = 4, .supplier = "supplier2"},{.display_name = "part5", .id = 5, .supplier = "supplier2"},{.display_name = "part6", .id = 6, .supplier = "supplier2"},
        {.display_name = "part7", .id = 7, .supplier = "supplier3"},{.display_name = "part8", .id = 8, .supplier = "supplier3"},{.display_name = "part9", .id = 9, .supplier = "supplier3"},
    };
    int part_cnt = sizeof(parts) / sizeof(part_t);
    printf("no. of parts: %d\n\n", part_cnt);


    // Initialize data structure - modules with parts assigned
    /* MODULES ──► PARTS
    ┌──────────┐
    │ module1  │──► part1 (1) ──► part2 (3) ──► part3 (2)
    └──────────┘
    ┌──────────┐
    │ module2  │──► part3 (8) ──► part4 (7) ──► part5 (4) ──► part6 (5) ──► part7 (2)
    └──────────┘
    ┌──────────┐
    │ module3  │──► part6 (4) ──► part7 (2) ──► part8 (1) ──► part9 (3)
    └──────────┘
     */
    part_list_t parts_q[] = {
        make_part_list(
            &(part_with_quantity_t){&parts[0],1 }, &(part_with_quantity_t){&parts[1], 3}, &(part_with_quantity_t){&parts[2], 2}),
        make_part_list(
            &(part_with_quantity_t){&parts[2],8}, &(part_with_quantity_t){&parts[3],7}, &(part_with_quantity_t){&parts[4],4},
            &(part_with_quantity_t){&parts[5],5}, &(part_with_quantity_t){&parts[6],2}),
        make_part_list(
            &(part_with_quantity_t){&parts[5],4}, &(part_with_quantity_t){&parts[6],2}, &(part_with_quantity_t){&parts[7],1},
            &(part_with_quantity_t){&parts[8],3})
    };
    module_with_parts_t module_with_parts[module_cnt];
    for (int i = 0; i < module_cnt; i++) {
        module_with_parts[i].m = modules[i];
        module_with_parts[i].p = parts_q[i];
    }

    // Traverse and print
    print_modules(module_with_parts, module_cnt);

    // initialize data structure - parts with modules assigned
    /*    PARTS ──► MODULES
       ┌────────┐
     ┌─┤ part1  ├──► module1 (1)
     │ ├────────┤
     ├─┤ part2  ├──► module1 (3)
     │ ├────────┤
     └─┤ part3  ├──► module1 (2) ──► module2 (8)
       ├────────┤
     ┌─┤ part4  ├──► module2 (7)
     │ ├────────┤
     ├─┤ part5  ├──► module2 (4)
     │ ├────────┤
     └─┤ part6  ├──► module2 (5) ──► module3 (4)
       ├────────┤
     ┌─┤ part7  ├──► module2 (2) ──► module3 (2)
     │ ├────────┤
     ├─┤ part8  ├──► module3 (1)
     │ ├────────┤
     └─┤ part9  ├──► module3 (3)
       └────────┘
*/
    module_list_t modules_q[] = {
        make_module_list(&(module_with_quantity_t){&modules[0],1}),
        make_module_list(&(module_with_quantity_t){&modules[0],2}),
        make_module_list(&(module_with_quantity_t){&modules[0],3}, &(module_with_quantity_t){&modules[1],8}),
        make_module_list(&(module_with_quantity_t){&modules[1],7}),
        make_module_list(&(module_with_quantity_t){&modules[1],4}),
        make_module_list(&(module_with_quantity_t){&modules[1],5}, &(module_with_quantity_t){&modules[2],4}),
        make_module_list(&(module_with_quantity_t){&modules[1],2}, &(module_with_quantity_t){&modules[2],2}),
        make_module_list(&(module_with_quantity_t){&modules[2],1}),
        make_module_list(&(module_with_quantity_t){&modules[2],3})};
    part_with_modules_t part_with_modules[part_cnt];
    for (int i = 0; i < part_cnt; i++) {
        part_with_modules[i].p = parts[i];
        part_with_modules[i].m = modules_q[i];
    }

    // Traverse and print
    print_parts(part_with_modules, part_cnt);

    // Aggregate and print
    print_parts_agg(part_with_modules, part_cnt);

    return 0;
}