# buildifier: disable=module-docstring
load("aspect_helpers.bzl", "list_append", "list_extend", "location")

# buildifier: disable=function-docstring
SharedLibrariesInfo = provider(fields = {
    "targets": "list of dependent shared libraries targets",
})

def _copy_dynamic_libraries_to_binary_aspect_impl(target, ctx):
    rule = ctx.rule
    # describe(rule, 'rule')
    # print('\n%s(%s)' % (target.label, rule.kind))

    target_list = []

    if rule.kind == "cc_import":
        shared_library = rule.attr.shared_library

        # cc_import rule may have "system_provided=1" specified and then shared_library is None.
        if shared_library:
            if SharedLibrariesInfo in shared_library:
                # print('%s shared_library[SharedLibrariesInfo] = %s' % (location(target, rule), shared_library[SharedLibrariesInfo]))
                list_extend(target_list, shared_library[SharedLibrariesInfo].targets)
            elif type(shared_library) == "Target":
                # This is the case when cc_import points to external binary
                list_append(target_list, shared_library)
            else:
                fail("Unexpected type in shared_library attribute. %s" % location(target, rule))

    if rule.kind == "tab_cc_shared_library_internal_rule":
        list_append(target_list, target)

    if rule.kind == "tab_cc_import_shared_lib_internal_rule":
        list_append(target_list, target)

    all_deps = []
    if hasattr(rule.attr, "implementation_deps"):
        all_deps.extend(rule.attr.implementation_deps)
    if hasattr(rule.attr, "deps"):
        all_deps.extend(rule.attr.deps)
    if hasattr(rule.attr, "data"):
        all_deps.extend(rule.attr.data)

    for dep in all_deps:
        if SharedLibrariesInfo in dep:
            dep_targets = dep[SharedLibrariesInfo].targets
            list_extend(target_list, dep_targets)

    return SharedLibrariesInfo(targets = target_list)

copy_dynamic_libraries_to_binary_aspect = aspect(
    implementation = _copy_dynamic_libraries_to_binary_aspect_impl,
    provides = [SharedLibrariesInfo],
    attr_aspects = ["implementation_deps", "deps", "imported_target", "shared_library", "data"],
    apply_to_generating_rules = True,
)

# buildifier: disable=function-docstring
def _get_target_files(target):
    target_files = []
    source_files = target.files.to_list()
    for source_file in source_files:
        target_files.append(source_file)
    if OutputGroupInfo in target:
        output_group_info = target[OutputGroupInfo]

        # describe(output_group_info, '_copy_dynamic_libraries_to_binary_impl output_group_info')
        if "pdb_file" in output_group_info:
            # describe(output_group_info.pdb_file.to_list(), '_copy_dynamic_libraries_to_binary_impl output_group_info.pdb_file.to_list()')
            target_files.extend(output_group_info.pdb_file.to_list())
        if "aliases" in output_group_info:
            # describe(output_group_info.aliases.to_list(), '_copy_dynamic_libraries_to_binary_impl output_group_info.aliases.to_list()')
            target_files.extend(output_group_info.aliases.to_list())
    return target_files

# buildifier: disable=function-docstring
def _copy_dynamic_libraries_to_binary_impl(ctx):
    target_list = []

    # print("\ncopy_dynamic_libraries_to_binary(%s)" % ctx.label)
    for dep in ctx.attr.implementation_deps:
        dep_targets = dep[SharedLibrariesInfo].targets

        # print('\ndep %s brings targets %s' % (dep.label, dep_targets))
        # describe(dep, 'dep')
        list_extend(target_list, dep_targets)

    current_workspace = ctx.label.workspace_name
    current_package = ctx.label.package

    files_to_copy = []  # Files to be symlinked to the output folder.
    runfiles = []  # Files from the same package which should not be symlinked to the output folder, but still should be listed as runfiles.
    for target in target_list:
        # describe(target, "target")
        target_files = _get_target_files(target)

        # print("\nTarget %s brings files %s" % (target, target_files))
        if target.label.workspace_name != current_workspace or target.label.package != current_package:
            # target from another package - we need to copy all its output files.
            files_to_copy.extend(target_files)
        else:
            # We get here when current target belongs to the same package as the current one.
            # In most typical case such target output files are already present in the output folder
            # and we don't need to copy them, but if some of its files actually come from another package
            # we still need to copy them.
            for target_file in target_files:
                if target_file.owner.workspace_name != current_workspace or target_file.owner.package != current_package:
                    files_to_copy.extend(target_files)
                else:
                    runfiles.append(target_file)

    new_symlinks = []
    for input_file in files_to_copy:
        new_symlink = ctx.actions.declare_file(input_file.basename)
        ctx.actions.symlink(output = new_symlink, target_file = input_file)

        # print('Created symlink from %s to %s' % (new_symlink, input_file.path))
        new_symlinks.append(new_symlink)

    # describe(new_symlinks, '_copy_dynamic_libraries_to_binary_impl new_symlinks for %s' % ctx.label)

    runfiles.extend(new_symlinks)

    # describe(runfiles, '_copy_dynamic_libraries_to_binary_impl runfiles extended for %s' % ctx.label)
    return [
        DefaultInfo(
            files = depset(direct = new_symlinks),
            runfiles = ctx.runfiles(files = runfiles),
        ),
        # OutputGroupInfo(_validation = depset(direct = all_output_files)),
    ]

copy_dynamic_libraries_to_binary = rule(
    implementation = _copy_dynamic_libraries_to_binary_impl,
    attrs = {
        "implementation_deps": attr.label_list(
            mandatory = True,
            aspects = [copy_dynamic_libraries_to_binary_aspect],
        ),
    },
)
