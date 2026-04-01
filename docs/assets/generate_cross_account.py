#!/usr/bin/env python3
"""Generate Excalidraw diagram for cross-account log retention flow."""

import json
import time

seed_counter = 500
index_counter = 0


def next_seed():
    global seed_counter
    seed_counter += 1
    return seed_counter


def next_index():
    global index_counter
    chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    prefix = chr(ord("a") + index_counter // len(chars))
    suffix = chars[index_counter % len(chars)]
    index_counter += 1
    return f"{prefix}{suffix}"


def make_rect(id, x, y, w, h, bg="#e7f5ff", stroke_width=2,
              bound_elements=None, roundness=None):
    return {
        "id": id, "type": "rectangle",
        "x": x, "y": y, "width": w, "height": h,
        "strokeColor": "#1e1e1e", "backgroundColor": bg,
        "fillStyle": "solid", "strokeWidth": stroke_width,
        "strokeStyle": "solid", "roughness": 1, "opacity": 100,
        "angle": 0, "seed": next_seed(), "version": 1,
        "isDeleted": False, "boundElements": bound_elements or [],
        "link": None, "locked": False, "groupIds": [],
        "frameId": None, "roundness": roundness,
        "index": next_index(),
        "updated": int(time.time() * 1000),
        "versionNonce": next_seed(),
    }


def make_text(id, x, y, text, font_size=16, color="#1e1e1e",
              text_align="center", container_id=None, vertical_align="top"):
    line_count = text.count("\n") + 1
    max_line_len = max(len(line) for line in text.split("\n"))
    return {
        "id": id, "type": "text",
        "x": x, "y": y,
        "width": font_size * 0.62 * max_line_len,
        "height": font_size * 1.25 * line_count,
        "text": text, "originalText": text,
        "fontSize": font_size, "fontFamily": 1,
        "textAlign": text_align, "verticalAlign": vertical_align,
        "strokeColor": color, "backgroundColor": "transparent",
        "fillStyle": "solid", "strokeWidth": 1,
        "strokeStyle": "solid", "roughness": 1, "opacity": 100,
        "angle": 0, "seed": next_seed(), "version": 1,
        "isDeleted": False, "boundElements": [],
        "link": None, "locked": False, "groupIds": [],
        "frameId": None, "roundness": None,
        "containerId": container_id, "autoResize": True,
        "lineHeight": 1.25, "baseline": int(font_size * 0.88),
        "index": next_index(),
        "updated": int(time.time() * 1000),
        "versionNonce": next_seed(),
    }


def make_arrow(id, x, y, points, start_id=None, end_id=None,
               style="solid", color="#1e1e1e"):
    return {
        "id": id, "type": "arrow",
        "x": x, "y": y,
        "width": abs(points[-1][0] - points[0][0]),
        "height": abs(points[-1][1] - points[0][1]),
        "strokeColor": color, "backgroundColor": "transparent",
        "fillStyle": "solid", "strokeWidth": 2,
        "strokeStyle": style, "roughness": 1, "opacity": 100,
        "angle": 0, "seed": next_seed(), "version": 1,
        "isDeleted": False, "boundElements": [],
        "link": None, "locked": False, "groupIds": [],
        "frameId": None, "roundness": None,
        "index": next_index(),
        "points": points,
        "startBinding": {
            "elementId": start_id, "focus": 0,
            "gap": 5, "fixedPoint": None
        } if start_id else None,
        "endBinding": {
            "elementId": end_id, "focus": 0,
            "gap": 5, "fixedPoint": None
        } if end_id else None,
        "startArrowhead": None, "endArrowhead": "arrow",
        "elbowed": False,
        "updated": int(time.time() * 1000),
        "versionNonce": next_seed(),
    }


elements = []

# --- Management Account frame ---
mgmt_frame = make_rect(
    "mgmt_frame", 20, 20, 320, 220,
    bg="#fff4e6", stroke_width=2, roundness={"type": 3},
    bound_elements=[{"id": "mgmt_title", "type": "text"}],
)
elements.append(mgmt_frame)

mgmt_title = make_text(
    "mgmt_title", 0, 0, "Management Account",
    font_size=14, color="#e67700", container_id="mgmt_frame",
)
elements.append(mgmt_title)

# Lambda box inside mgmt
lambda_box = make_rect(
    "lambda_box", 50, 80, 260, 80,
    bg="#fff4e6", stroke_width=2, roundness={"type": 3},
    bound_elements=[
        {"id": "lambda_label", "type": "text"},
        {"id": "arrow_assume", "type": "arrow"},
    ],
)
elements.append(lambda_box)

lambda_label = make_text(
    "lambda_label", 0, 0, "org-governance Lambda\nsts:AssumeRole",
    font_size=14, container_id="lambda_box", vertical_align="middle",
)
elements.append(lambda_label)

# CloudWatch Logs in management account
cw_box = make_rect(
    "cw_box", 90, 175, 180, 45,
    bg="#e5dbff", stroke_width=1, roundness={"type": 3},
    bound_elements=[
        {"id": "cw_label", "type": "text"},
        {"id": "arrow_cw", "type": "arrow"},
    ],
)
elements.append(cw_box)

cw_label = make_text(
    "cw_label", 0, 0, "CloudWatch Logs",
    font_size=12, container_id="cw_box", vertical_align="middle",
)
elements.append(cw_label)

# Arrow from lambda to CW
arrow_cw = make_arrow(
    "arrow_cw", 180, 160, [[0, 0], [0, 15]],
    start_id="lambda_box", end_id="cw_box", style="dashed", color="#868e96",
)
elements.append(arrow_cw)

# --- Member Account frame ---
member_frame = make_rect(
    "member_frame", 460, 20, 320, 220,
    bg="#ebfbee", stroke_width=2, roundness={"type": 3},
    bound_elements=[{"id": "member_title", "type": "text"}],
)
elements.append(member_frame)

member_title = make_text(
    "member_title", 0, 0, "Member Account",
    font_size=14, color="#2b8a3e", container_id="member_frame",
)
elements.append(member_title)

# IAM Role box
role_box = make_rect(
    "role_box", 490, 70, 260, 95,
    bg="#ffe3e3", stroke_width=2, roundness={"type": 3},
    bound_elements=[
        {"id": "role_label", "type": "text"},
        {"id": "arrow_assume", "type": "arrow"},
        {"id": "arrow_logs", "type": "arrow"},
    ],
)
elements.append(role_box)

role_label = make_text(
    "role_label", 0, 0,
    "InfraHouseLogRetention\nlogs:DescribeLogGroups\nlogs:PutRetentionPolicy",
    font_size=13, container_id="role_box", vertical_align="middle",
)
elements.append(role_label)

# CloudWatch Logs in member account
member_cw_box = make_rect(
    "member_cw_box", 530, 180, 180, 45,
    bg="#e5dbff", stroke_width=1, roundness={"type": 3},
    bound_elements=[
        {"id": "member_cw_label", "type": "text"},
        {"id": "arrow_logs", "type": "arrow"},
    ],
)
elements.append(member_cw_box)

member_cw_label = make_text(
    "member_cw_label", 0, 0, "CloudWatch Logs",
    font_size=12, container_id="member_cw_box", vertical_align="middle",
)
elements.append(member_cw_label)

# Arrow from role to member CW logs
arrow_logs = make_arrow(
    "arrow_logs", 620, 165, [[0, 0], [0, 15]],
    start_id="role_box", end_id="member_cw_box", color="#2b8a3e",
)
elements.append(arrow_logs)

# --- Main arrow: Lambda -> IAM Role (sts:AssumeRole) ---
arrow_assume = make_arrow(
    "arrow_assume", 310, 120, [[0, 0], [180, 0]],
    start_id="lambda_box", end_id="role_box", color="#e67700",
)
elements.append(arrow_assume)

# Label on the arrow
arrow_label = make_text(
    "arrow_assume_label", 355, 100, "sts:AssumeRole",
    font_size=12, color="#e67700",
)
elements.append(arrow_label)

# Build the file
doc = {
    "type": "excalidraw",
    "version": 2,
    "source": "https://app.excalidraw.com",
    "elements": elements,
    "appState": {
        "gridSize": 20,
        "gridStep": 5,
        "gridModeEnabled": False,
        "viewBackgroundColor": "#ffffff",
    },
    "files": {},
}

outpath = "docs/assets/cross-account-log-retention.excalidraw"
with open(outpath, "w") as f:
    json.dump(doc, f, indent=2)
    f.write("\n")

# Verify
errors = []
for el in doc["elements"]:
    if el["type"] == "text":
        if "originalText" not in el:
            errors.append(f"{el['id']}: missing originalText")
        if el.get("height") is None:
            errors.append(f"{el['id']}: height is null")
        if "lineHeight" not in el:
            errors.append(f"{el['id']}: missing lineHeight")
    if "strokeStyle" not in el:
        errors.append(f"{el['id']}: missing strokeStyle")
    if "frameId" not in el:
        errors.append(f"{el['id']}: missing frameId")
    if "index" not in el:
        errors.append(f"{el['id']}: missing index")
if errors:
    print(f"ERRORS ({len(errors)}):")
    for e in errors:
        print(f"  {e}")
else:
    print(f"OK: {len(doc['elements'])} elements, all valid")
    print(f"Written to {outpath}")
