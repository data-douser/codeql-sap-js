from functools import reduce
from yaml import safe_load
import re


def read_file():
    with open("ui5-data-extensions.yml", "r") as f:
        return safe_load(f)


def make_source_call_expr(obj_name, api_lang_string):
    out = re.sub(r"Member\[([a-zA-Z]+)\]", r"\1", api_lang_string)
    out = re.sub(r"ReturnValue", "()", out)
    out = re.sub(r"Instance", "", out)
    out = re.sub(r"\.\(\)", "()", out)
    out = out if out.startswith("jQuery") else obj_name + out
    return f"var value = {out};"


def make_module_obj_string(dep_paths):
    out = ""
    for dep_path in dep_paths:
        if dep_path.startswith("jQuery"):
            continue
        else:
            out += dep_path.split("/")[-1] + ",\n"
    return out


def make_dep_paths_string(dep_paths):
    return reduce(lambda acc, elem: acc + f'"{elem}",\n', dep_paths, "")


def make_init_expr(obj_name, path):
    return f"var {obj_name} = new {path.split('/')[-1]}();"


def make_source_fixture_for_row(row):
    path, api_lang_string, _ = row
    obj_name = "obj"  # very boring
    init_expr = make_init_expr(obj_name, path) if path != "global" else ""
    call_expr = make_source_call_expr(obj_name, api_lang_string)
    return init_expr + "\n" + call_expr


def make_source_body(rows):
    return reduce(
        lambda acc, elem: acc + elem + "\n", map(make_source_fixture_for_row, rows)
    )


def make_source_dep_paths(deserialized_yaml):
    return set(
        filter(
            lambda string: string != "global",
            map(lambda lst: lst[0], deserialized_yaml["extensions"][1]["data"]),
        )
    )


def write_sap_ui_define_source(dep_paths, rows):
    return f"""
    sap.ui.require([{make_dep_paths_string(dep_paths)}],
        function({make_module_obj_string(dep_paths)}) {{
            {make_source_body(rows)}
    }});
    """


def make_arglist_str_from_argument(argument):
    """
    argument == "Argument[2]" or
    argument == "Argument[0..2]" or
    argument == "Argument[0..]"

    output's like (code0, code1, code2) depending on argument.
    """
    max_try = 5
    argument = re.search(r"Argument\[(.+)\]", argument).group(1)
    if ".." not in argument:
        lower, upper = None, int(argument)
    else:
        lower, upper = argument.split("..")
    if upper == "" and ".." in argument:
        range_ = range(0, max_try + 1)
    else:
        range_ = range(0, int(upper) + 1)
    arglist_str = reduce(
        lambda acc, elem: acc + elem + ", ", map(lambda num: f"code{num}", range_), ""
    )
    return f"({arglist_str})"


def make_sink_call_expr(obj_name, api_lang_string):
    out = re.sub(r"Member\[([a-zA-Z]+)\]", r"\1", api_lang_string)
    out = re.sub(r"Instance", "", out)
    out = out if out.startswith("jQuery") else obj_name + out
    # need to deal with the Argument[..] thing.
    # out = re.sub(r"ReturnValue", "()", out)
    if re.search(r"Argument\[(.+)\]", out):
        raw_argument = re.search(r"Argument\[(.+)\]", out).group(0)
        out = re.sub(
            r"\.Argument\[(.+)\]", make_arglist_str_from_argument(raw_argument), out
        )
    return f"var value = {out};"


def make_sink_fixture_for_row(row):
    path, api_lang_string, _ = row
    obj_name = "obj"  # very boring
    init_expr = make_init_expr(obj_name, path) if path != "global" else ""
    call_expr = make_sink_call_expr(obj_name, api_lang_string)
    return init_expr + "\n" + call_expr


def make_sink_body(rows):
    return reduce(
        lambda acc, elem: acc + elem + "\n", map(make_sink_fixture_for_row, rows)
    )


def make_sink_dep_paths(deserialized_yaml):
    return set(
        filter(
            lambda string: string != "global" and "/" in string,
            map(lambda lst: lst[0], deserialized_yaml["extensions"][2]["data"]),
        )
    )


def write_sap_ui_define_sink(dep_paths, rows):
    return f"""
    sap.ui.require([{make_dep_paths_string(dep_paths)}],
        function({make_module_obj_string(dep_paths)}) {{
             {make_sink_body(rows)}
    }}
    );
    """


def main():
    deserialized_yaml = read_file()

    source_dep_paths = make_source_dep_paths(deserialized_yaml)
    source_rows = deserialized_yaml["extensions"][1]["data"]
    sap_ui_define_source = write_sap_ui_define_source(source_dep_paths, source_rows)
    with open("sourceTest.js", "w+") as source_test_file:
        source_test_file.write(sap_ui_define_source)
        source_test_file.write("\n")

    sink_dep_paths = make_sink_dep_paths(deserialized_yaml)
    sink_rows = deserialized_yaml["extensions"][2]["data"]
    sap_ui_define_sink = write_sap_ui_define_sink(sink_dep_paths, sink_rows)
    with open("sinkTest.js", "w+") as sink_test_file:
        sink_test_file.write(sap_ui_define_sink)
        sink_test_file.write("\n")


if __name__ == "__main__":
    main()

test_sap_source = [
    "sap/ui/codeeditor/CodeEditor",
    "Instance.Member[getCurrentValue].ReturnValue",
    "remote",
]

test_sap_field_source = [
    "sap/ui/richtexteditor/RichTextEditor",
    "Instance.Member[value]",
    "remote",
]

test_jquery_source = [
    "global",
    "Member[jQuery].Member[sap].Member[getUriParameters].ReturnValue.Member[get].ReturnValue",
    "remote",
]

test_sap_sink = ["TODO"]

test_sap_field_sink = ["TODO"]

test_jquery_sink = ["TODO"]
