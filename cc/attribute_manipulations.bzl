# buildifier: disable=module-docstring
def add_attribute(attrs, attr_name, value):
    """
    Add attribute to attrs.  If 'attr_name' already exists, add 'value' to existing value.

    Args:
        attrs: A dict of attributes to modify
        attr_name: The name of the attribute to add or append
        value: The value to add or append
    Returns:
        None
    """

    attribute = attrs.get(attr_name)
    if attribute:
        new_attribute = attribute + value
    else:
        new_attribute = value
    attrs[attr_name] = new_attribute

def add_attribute_if_not_present(attrs, attr_name, value):
    """
    Add attribute to attrs if not present.

    Args:
        attrs: A dict of attributes to modify
        attr_name: The name of the attribute to add
        value: The value to add
    Returns:
        None
    """

    attribute = attrs.get(attr_name)
    if attribute:
        return
    attrs[attr_name] = value

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
        this_list: A list to modifiy
        additional_list: The list new items to add to 'this_list'
    Returns:
        None
    """

    # print("Extend list %s with the list %s" % (this_list, additional_list))
    for item in additional_list:
        list_append(this_list, item)

def list_add(this_list, value):
    """
    Append or extend list with value or values not already present.

    Args:
        this_list: A list to modify
        value: The new item or items to append
    Returns:
        None
    """

    if type(value) == "list":
        list_extend(this_list, value)
    else:
        list_append(this_list, value)

def add_to_list_attribute(attrs, attr_name, value):
    """
    Add or modify an attribute List in attrs.

    Attribute type can be any of None, List or Select.  Attribute will be created and added
    to 'attrs' if not present.

    Value can be any of None, String, List or Select.  String and strings in List will be added
    if not present.

    If attribute is of type List and value is of type Select, then the list will be converted to
    a select that has a default condition whose value is the list and the select value will be
    added.

    Args:
        attrs: A dict of attributes to modify
        attr_name: The name of the attribute to add or append
        value: The value to add (None, String, List or Select)
    Returns:
        None
    """

    # describe(attrs.get(attr_name), 'add_to_list_attribute BEGIN: attrs[%s] for rule %s' % (attr_name, attrs["name"]))
    attrs[attr_name] = _add_to_list(attrs.get(attr_name), value)
    # describe(attrs.get(attr_name), 'add_to_list_attribute END: attrs[%s] for rule %s' % (attr_name, attrs["name"]))

# buildifier: disable=function-docstring
def _add_to_list(this_list, value):
    if not this_list:
        if not value:
            return None
        elif type(value) == "list":
            return value
        elif type(value) == "select":
            return value
        else:
            return [value]  # list from a single value
    elif type(this_list) == "list":
        if not value:
            return this_list
        elif type(value) == "list":
            new_list = list(this_list)  # Clone the list not to mutate existing collection.
            list_extend(new_list, value)
            return new_list
        elif type(value) == "select":
            new_list = list(this_list)  # Clone the list not to mutate existing collection.

            # Wrap the list with select
            wrapped_list = select({"//conditions:default": new_list})
            return wrapped_list + value  # select + select
        else:
            new_list = list(this_list)  # Clone the list not to mutate existing collection.
            list_append(new_list, value)
            return new_list
    elif type(this_list) == "select":
        if not value:
            return this_list
        elif type(value) == "list":
            return this_list + value  # select + list
        elif type(value) == "select":
            return this_list + value  # select + select
        else:
            return this_list + [value]  # select + list from a single value
    else:
        fail("add_to_list first argument is %s. Only list or select can be appened to." % type(this_list))

def dict_append(this_dict, new_key, new_value):
    """
    Append new_key to the dict if it is not already present.

    Args:
        this_dict: A dict to modify
        new_key: The new key to append
        new_value: The new value to append
    Returns:
        None
    """

    if new_key in this_dict:
        return
    this_dict[new_key] = new_value

def dict_extend(this_dict, additional_dict):
    """
    Extend the dict with only new items from additional dict.

    Args:
        this_dict: A dict to modify
        additional_dict: The dict of new items to add to 'this_dict'
    Returns:
        None
    """

    # print("Extend dict %s with the dict %s" % (this_dict, additional_dict))
    for key, value in additional_dict.items():
        dict_append(this_dict, key, value)

def add_to_dict_attribute(attrs, attr_name, new_dict):
    """
    Add or modify an attribute Dict in attrs if not present.

    Attribute type can be any of None, Dict or Select.  Attribute will be created and added
    to 'attrs' if not present.

    Value can be any of None, Dict or Select.  Keys and values will only be added if not present.

    If attribute is of type Dict and new_dict is of type Select, then the dict will be converted to
    a select that has a default condition whose value is the dict and the select value will be
    added.

    Args:
        attrs: A dict of attributes to modify
        attr_name: The name of the attribute to add or modify
        new_dict: The value to add (None, Dict or Select)
    Returns:
        None
    """

    attrs[attr_name] = _add_to_dict(attrs.get(attr_name), new_dict)

#buildifier: disable=funciton-docstring
def _add_to_dict(this_dict, new_dict):
    if not this_dict:
        if not new_dict:
            return None
        else:
            return new_dict
    elif type(this_dict) == "dict":
        if not new_dict:
            return this_dict
        elif type(new_dict) == "select":
            cloned_dict = dict(this_dict)  # Clone the dict not to mutate existing collection.

            # Wrap the dict with select
            wrapped_dict = select({"//conditions:default": cloned_dict})
            return wrapped_dict + new_dict  # select + select
        else:
            cloned_dict = dict(this_dict)  # Clone the dict not to mutate existing collection.
            dict_extend(cloned_dict, new_dict)
            return cloned_dict
    elif type(this_dict) == "select":
        if not new_dict:
            return this_dict
        return this_dict + new_dict  # select + dict || select + select
    else:
        fail("extend_dict first argument is %s. Only dict or select can be extended." % type(this_dict))

def location(attrs):
    return "Repository: %s, Package: %s, Rule: %s" % (native.repository_name(), native.package_name(), attrs.get("name"))
