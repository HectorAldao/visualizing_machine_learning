import csv
import math
from collections import Counter


def entropy(rows):
    total = len(rows)
    class_counts = Counter(row["class"] for row in rows)

    if len(class_counts) == 1:
        return 0.0

    return -sum(
        (count / total) * math.log2(count / total)
        for count in class_counts.values()
    )


def information_gain(rows, attribute):
    total = len(rows)
    weighted_entropy = 0

    for value in sorted({row[attribute] for row in rows}):
        subset = [row for row in rows if row[attribute] == value]
        weighted_entropy += (len(subset) / total) * entropy(subset)

    return entropy(rows) - weighted_entropy


def node_purity(rows):
    class_counts = Counter(row["class"] for row in rows)
    most_common_count = class_counts.most_common(1)[0][1]

    return most_common_count, len(rows), class_counts


def majority_class(rows):
    return Counter(row["class"] for row in rows).most_common(1)[0][0]


def build_id3(rows, attributes, next_node_id):
    node_id = next_node_id
    next_node_id += 1
    class_counts = Counter(row["class"] for row in rows)

    if len(class_counts) == 1:
        return {
            "id": node_id,
            "label": next(iter(class_counts)),
            "rows": rows,
            "branches": {},
        }, next_node_id

    if not attributes:
        return {
            "id": node_id,
            "label": majority_class(rows),
            "rows": rows,
            "branches": {},
        }, next_node_id

    best_attribute = max(attributes, key=lambda attribute: information_gain(rows, attribute))
    remaining_attributes = [attribute for attribute in attributes if attribute != best_attribute]
    node = {
        "id": node_id,
        "label": best_attribute,
        "rows": rows,
        "branches": {},
    }

    for value in sorted({row[best_attribute] for row in rows}):
        subset = [row for row in rows if row[best_attribute] == value]
        child, next_node_id = build_id3(subset, remaining_attributes, next_node_id)
        node["branches"][value] = child

    return node, next_node_id


def print_tree(node, prefix=""):
    won, total, _ = node_purity(node["rows"])
    print(f"{prefix}[Nodo {node['id']}] {node['label']} (pureza: {won}/{total} = {won / total:.4f})")

    branch_count = len(node["branches"])
    for index, (value, child) in enumerate(node["branches"].items()):
        is_last = index == branch_count - 1
        connector = "`--" if is_last else "|--"
        child_prefix = "    " if is_last else "|   "
        print(f"{prefix}{connector} {value}")
        print_tree(child, prefix + child_prefix)


def print_node_purities(node):
    won, total, class_counts = node_purity(node["rows"])
    exact_purity = f"{won}/{total}"
    percentage = won / total
    classes = dict(sorted(class_counts.items()))

    print(
        f"Nodo {node['id']}: pureza={exact_purity} = {percentage:.4f}, "
        f"entropia={entropy(node['rows']):.4f}, muestras={total}, clases={classes}"
    )

    for child in node["branches"].values():
        print_node_purities(child)


def main():
    with open("frutas.csv", newline="") as csv_file:
        rows = list(csv.DictReader(csv_file))

    attributes = [column for column in rows[0] if column != "class"]
    tree, _ = build_id3(rows, attributes, next_node_id=0)

    print("Arbol de decision ID3 basico (criterio: entropia):")
    print_tree(tree)

    print()
    print("Pureza de los nodos:")
    print_node_purities(tree)


if __name__ == "__main__":
    main()
