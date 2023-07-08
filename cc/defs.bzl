# Modelled after https://github.com/bazelbuild/rules_cc/blob/master/cc/defs.bzl
# buildifier: disable=module-docstring
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_test")
load("copy_dynamic_libraries_to_binary.bzl", "copy_dynamic_libraries_to_binary")
load("attribute_manipulations.bzl", "add_to_list_attribute")

# buildifier: disable=function-docstring
def add_shared_libraries_to_data(attrs):
    name = attrs["name"]

    list_to_scan = []
    deps = attrs.get("deps")
    if deps:
        list_to_scan += deps  # Use += instead of "extend" as the second argument may be "select" statement.

    implementation_deps = attrs.get("implementation_deps")
    if implementation_deps:
        list_to_scan += implementation_deps  # Use += instead of "extend" as the second argument may be "select" statement.

    data = attrs.get("data")
    if data:
        list_to_scan += data  # Use += instead of "extend" as the second argument may be "select" statement.

    if list_to_scan:
        copy_dynamic_libraries_rule_name = "__copy_dynamic_libraries_to_binary_" + name
        copy_dynamic_libraries_to_binary(
            name = copy_dynamic_libraries_rule_name,
            implementation_deps = list_to_scan,
        )
        add_to_list_attribute(attrs, "data", copy_dynamic_libraries_rule_name)

# buildifier: disable=function-docstring
def cc_binary_copy_deps(**attrs):
    add_shared_libraries_to_data(attrs)
    cc_binary(**attrs)

# buildifier: disable=function-docstring
def cc_test_copy_deps(**attrs):
    add_shared_libraries_to_data(attrs)

    cc_test(**attrs)
