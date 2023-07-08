# buildifier: disable=module-docstring
# buildifier: disable=function-docstring
def location(target, rule):
    location = str(target.label)
    if hasattr(rule.attr, "generator_function"):
        location += " (%s at %s)" % (rule.attr.generator_function, rule.attr.generator_location)
    return location

def list_append(this_list, new_item):
    """
    Append item to the list if it is not already present.

    Args:
        this_list: A list to modify
        new_item: The new item to append
    Returns:
        None
    """

    for item in this_list:
        if item == new_item:
            return
    this_list.append(new_item)

def list_extend(this_list, additional_list):
    """
    Extend the list with only new items from additional list.

    Args:
        this_list: A list to modify
        additional_list: The list new items to add to 'this_list'
    Returns:
        None
    """

    for item in additional_list:
        list_append(this_list, item)
