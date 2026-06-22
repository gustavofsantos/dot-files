"""Kernel data model for system-cartographer — the FIXED floor.

This module is the single source of truth for what ships in the plugin and is
written verbatim into a repo's `.cartographer/` on init. Nothing here is
user-editable; the instance grows by *extension* (see meta-schema), never by
rewriting these.

Two layers (read the README):
  - KERNEL_META_SCHEMA: the constitution. Bounds HOW the schema may grow.
  - KERNEL_SCHEMA:       the active schema, starts == kernel, grows by accept.
"""

# --- The constitution -------------------------------------------------------
# Growth is OPEN in content, CLOSED in form. Every legal extension adds one
# optional attribute to `node` or `edge`, and that attribute's shape must be
# exactly one of the four below. A validator and a future single reflective
# visualizer can be written against ANY evolved schema because of this.
KERNEL_META_SCHEMA = {
    "meta_schema_version": 1,
    "description": (
        "Constitution for system-cartographer. Defines the kernel and the "
        "bounded grammar by which the instance schema may be extended. "
        "Extensions accrete; they never redefine. Every accepted extension is "
        "recorded in schema-evolution.md as a decision."
    ),
    "entities": ["node", "edge"],
    "kernel": {
        "node": {
            "required": ["id", "role"],
            "attributes": {
                "id": {"shape": "scalar", "type": "string"},
                "role": {"shape": "scalar", "type": "string"},
            },
        },
        "edge": {
            "required": ["from", "to", "interaction"],
            "attributes": {
                "from": {"shape": "ref", "ref": "node"},
                "to": {"shape": "ref", "ref": "node"},
                "interaction": {"shape": "enum", "values": ["sync", "async"]},
            },
        },
    },
    "extension_rules": {
        # An extension may only target one of these entities...
        "allowed_targets": ["node", "edge"],
        # ...and its attribute must be exactly one of these four shapes.
        "allowed_shapes": {
            "enum": {"required_params": ["values"]},      # closed set of strings
            "scalar": {"required_params": ["type"],       # one typed value
                       "allowed_types": ["string", "number", "boolean"]},
            "ref": {"required_params": ["ref"]},          # reference to a node id
            "tag": {"required_params": []},               # free-form set of labels
        },
        # In v1, EVERY extension is optional. Existing entries that lack an
        # earned attribute stay valid; the gap is a known-unknown, not an error.
        "extensions_always_optional": True,
        # Reserved, carried but UNUSED in v1 — lets a future single reflective
        # visualizer render any evolved instance without schema changes.
        "optional_extension_fields": ["visual_intent"],
        "visual_intent_hints": ["line-style", "color", "badge"],
        # Attribute names an extension may never shadow.
        "reserved_attribute_names": ["id", "role", "from", "to", "interaction"],
    },
}

# --- The active schema (starts identical to the kernel) ---------------------
# When an extension is accepted via /accept-schema-change, an entry is appended
# to the relevant `attributes` map (origin=extension, optional=true) and a
# summary is pushed to `extensions`. The kernel attributes are never touched.
KERNEL_SCHEMA = {
    "schema_version": 1,
    "based_on_meta_schema": 1,
    "node": {
        "required": ["id", "role"],
        "attributes": {
            "id": {"shape": "scalar", "type": "string", "origin": "kernel"},
            "role": {"shape": "scalar", "type": "string", "origin": "kernel"},
        },
    },
    "edge": {
        "required": ["from", "to", "interaction"],
        "attributes": {
            "from": {"shape": "ref", "ref": "node", "origin": "kernel"},
            "to": {"shape": "ref", "ref": "node", "origin": "kernel"},
            "interaction": {"shape": "enum", "values": ["sync", "async"],
                            "origin": "kernel"},
        },
    },
    # Earned extensions, in acceptance order. Empty at the floor.
    "extensions": [],
}

# --- The instance (empty at init) -------------------------------------------
EMPTY_MAP = {"nodes": [], "edges": []}

EVOLUTION_LOG_HEADER = (
    "# Schema evolution log\n\n"
    "Append-only decision record. Each entry is a schema extension that was\n"
    "*earned* by a reasoning need and *accepted* by a human via\n"
    "`/accept-schema-change`. This is the story of why the schema is shaped the\n"
    "way it is — not a changelog. Do not edit past entries.\n"
)
