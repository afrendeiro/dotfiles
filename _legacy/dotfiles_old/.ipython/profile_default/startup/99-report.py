def _identity(string):
    obj = globals()[string]
    return (
        "module"
        if hasattr(string, "__spec__")
        else (
            "module"
            if _inspect.ismodule(obj)
            else (
                "class"
                if _inspect.isclass(obj)
                else ("function" if _inspect.isfunction(obj) else "class")
            )
        )
    )


candidates = sorted(
    [x for x in locals() if (x not in _init and not x.startswith("_"))]
)

print("\n----- List of modifications since startup: -----\n")

for desc, can in sorted(zip(map(_identity, candidates), candidates)):
    print(f"Imported {desc}: '{can}'.")

_init = locals().copy()

# Constants
DATE = _dt.today().strftime("%Y-%m-%d")
IPYTHON = bool(_IPython.get_ipython())

for mod in sorted(
    [x for x in locals() if (x not in _init and not x.startswith("_"))]
):
    print(f"Declared constant: '{mod}'.")
