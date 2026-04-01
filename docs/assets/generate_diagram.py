#!/usr/bin/env python3
"""Generate Excalidraw architecture diagram for terraform-aws-iso27001."""
import json
import time

seed_counter = 100
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


def make_text(
    id, x, y, text, font_size=16, color="#1e1e1e",
    text_align="center", container_id=None, vertical_align="top",
):
    line_count = text.count("\n") + 1
    max_line_len = max(len(line) for line in text.split("\n"))
    return {
        "id": id,
        "type": "text",
        "x": x,
        "y": y,
        "width": font_size * 0.62 * max_line_len,
        "height": font_size * 1.25 * line_count,
        "text": text,
        "originalText": text,
        "fontSize": font_size,
        "fontFamily": 1,
        "textAlign": text_align,
        "verticalAlign": vertical_align,
        "strokeColor": color,
        "backgroundColor": "transparent",
        "fillStyle": "solid",
        "strokeWidth": 1,
        "strokeStyle": "solid",
        "roughness": 1,
        "opacity": 100,
        "angle": 0,
        "seed": next_seed(),
        "version": 1,
        "isDeleted": False,
        "boundElements": [],
        "link": None,
        "locked": False,
        "groupIds": [],
        "frameId": None,
        "roundness": None,
        "containerId": container_id,
        "autoResize": True,
        "lineHeight": 1.25,
        "baseline": int(font_size * 0.88),
        "index": next_index(),
        "updated": int(time.time() * 1000),
        "versionNonce": next_seed(),
    }


def make_rect(id, x, y, w, h, bg="#e7f5ff", stroke_width=2,
              bound_elements=None, roundness=None, stroke_style="solid"):
    return {
        "id": id,
        "type": "rectangle",
        "x": x,
        "y": y,
        "width": w,
        "height": h,
        "strokeColor": "#1e1e1e",
        "backgroundColor": bg,
        "fillStyle": "solid",
        "strokeWidth": stroke_width,
        "strokeStyle": stroke_style,
        "roughness": 1,
        "opacity": 100,
        "angle": 0,
        "seed": next_seed(),
        "version": 1,
        "isDeleted": False,
        "boundElements": bound_elements or [],
        "link": None,
        "locked": False,
        "groupIds": [],
        "frameId": None,
        "roundness": roundness,
        "index": next_index(),
        "updated": int(time.time() * 1000),
        "versionNonce": next_seed(),
    }


def make_arrow(id, x, y, points, start_id=None, end_id=None,
               style="solid", color="#1e1e1e"):
    dx = abs(points[-1][0] - points[0][0])
    dy = abs(points[-1][1] - points[0][1])
    return {
        "id": id,
        "type": "arrow",
        "x": x,
        "y": y,
        "width": dx if dx > 0 else 1,
        "height": dy if dy > 0 else 1,
        "strokeColor": color,
        "backgroundColor": "transparent",
        "fillStyle": "solid",
        "strokeWidth": 2,
        "strokeStyle": style,
        "roughness": 1,
        "opacity": 100,
        "angle": 0,
        "seed": next_seed(),
        "version": 1,
        "isDeleted": False,
        "boundElements": [],
        "link": None,
        "locked": False,
        "groupIds": [],
        "frameId": None,
        "roundness": None,
        "index": next_index(),
        "points": points,
        "startBinding": {
            "elementId": start_id, "focus": 0,
            "gap": 5, "fixedPoint": None,
        } if start_id else None,
        "endBinding": {
            "elementId": end_id, "focus": 0,
            "gap": 5, "fixedPoint": None,
        } if end_id else None,
        "startArrowhead": None,
        "endArrowhead": "arrow",
        "elbowed": False,
        "updated": int(time.time() * 1000),
        "versionNonce": next_seed(),
    }


def make_ellipse(id, x, y, w, h, bg="#e9ecef", bound_elements=None):
    return {
        "id": id,
        "type": "ellipse",
        "x": x,
        "y": y,
        "width": w,
        "height": h,
        "strokeColor": "#1e1e1e",
        "backgroundColor": bg,
        "fillStyle": "solid",
        "strokeWidth": 2,
        "strokeStyle": "solid",
        "roughness": 1,
        "opacity": 100,
        "angle": 0,
        "seed": next_seed(),
        "version": 1,
        "isDeleted": False,
        "boundElements": bound_elements or [],
        "link": None,
        "locked": False,
        "groupIds": [],
        "frameId": None,
        "roundness": {"type": 2},
        "index": next_index(),
        "updated": int(time.time() * 1000),
        "versionNonce": next_seed(),
    }


elements = []

# ── Title ──
elements.append(make_text("title", 200, 10, "terraform-aws-iso27001", font_size=28,
                           text_align="center", color="#1e1e1e"))

# ── AWS Account frame ──
elements.append(make_rect("account_frame", 40, 60, 880, 680,
                           bg="#f8f9fa", stroke_width=2,
                           stroke_style="dashed",
                           bound_elements=[{"id": "account_label", "type": "text"}]))
elements.append(make_text("account_label", 50, 65, "AWS Account",
                           font_size=14, color="#868e96",
                           text_align="left", container_id="account_frame"))

# ═══════════════════════════════════════════════════════════
# Row 1: GLOBAL RESOURCES (left side)
# ═══════════════════════════════════════════════════════════

global_x = 60
global_y = 100

elements.append(make_text("global_title", global_x, global_y,
                           "Global Resources (created once)",
                           font_size=14, color="#495057", text_align="left"))

# Primary Contact
pc_y = global_y + 30
elements.append(make_rect("primary_contact", global_x, pc_y, 180, 50,
                           bg="#e7f5ff", roundness={"type": 3},
                           bound_elements=[{"id": "primary_contact_lbl", "type": "text"}]))
elements.append(make_text("primary_contact_lbl", global_x, pc_y,
                           "Primary Contact", font_size=13,
                           container_id="primary_contact",
                           vertical_align="middle"))

# Security Contact
sc_x = global_x + 200
elements.append(make_rect("security_contact", sc_x, pc_y, 180, 50,
                           bg="#e7f5ff", roundness={"type": 3},
                           bound_elements=[{"id": "security_contact_lbl", "type": "text"}]))
elements.append(make_text("security_contact_lbl", sc_x, pc_y,
                           "Security Contact", font_size=13,
                           container_id="security_contact",
                           vertical_align="middle"))

# Password Policy
pp_y = pc_y + 65
elements.append(make_rect("password_policy", global_x, pp_y, 180, 50,
                           bg="#e7f5ff", roundness={"type": 3},
                           bound_elements=[{"id": "password_policy_lbl", "type": "text"}]))
elements.append(make_text("password_policy_lbl", global_x, pp_y,
                           "Password Policy\n(21 chars)", font_size=13,
                           container_id="password_policy",
                           vertical_align="middle"))

# S3 Public Access Block
elements.append(make_rect("s3_block", sc_x, pp_y, 180, 50,
                           bg="#ebfbee", roundness={"type": 3},
                           bound_elements=[{"id": "s3_block_lbl", "type": "text"}]))
elements.append(make_text("s3_block_lbl", sc_x, pp_y,
                           "S3 Public\nAccess Block", font_size=13,
                           container_id="s3_block",
                           vertical_align="middle"))

# ── IAM Section ──
iam_y = pp_y + 75
elements.append(make_rect("iam_frame", global_x, iam_y, 380, 120,
                           bg="#fff9db", stroke_width=1,
                           stroke_style="dashed",
                           bound_elements=[{"id": "iam_frame_lbl", "type": "text"}]))
elements.append(make_text("iam_frame_lbl", global_x + 5, iam_y + 3,
                           "IAM (Global)", font_size=11, color="#868e96",
                           text_align="left", container_id="iam_frame"))

# InfraHouseLogRetention role
lr_y = iam_y + 25
elements.append(make_rect("log_retention_role", global_x + 10, lr_y, 170, 50,
                           bg="#fff4e6", roundness={"type": 3},
                           bound_elements=[{"id": "log_retention_lbl", "type": "text"}]))
elements.append(make_text("log_retention_lbl", global_x + 10, lr_y,
                           "InfraHouse\nLogRetention", font_size=12,
                           container_id="log_retention_role",
                           vertical_align="middle"))

# GuardDuty EventBridge role
elements.append(make_rect("guardduty_role", global_x + 200, lr_y, 170, 50,
                           bg="#fff4e6", roundness={"type": 3},
                           bound_elements=[{"id": "guardduty_role_lbl", "type": "text"}]))
elements.append(make_text("guardduty_role_lbl", global_x + 200, lr_y,
                           "GuardDuty\nPublish Role", font_size=12,
                           container_id="guardduty_role",
                           vertical_align="middle"))

# Trust annotation for LogRetention
elements.append(make_text("trust_note", global_x + 15, lr_y + 55,
                           "Trusts: mgmt account root", font_size=10,
                           color="#868e96", text_align="left"))

# ═══════════════════════════════════════════════════════════
# Row 2: REGIONAL RESOURCES (right side, repeated per region)
# ═══════════════════════════════════════════════════════════

reg_x = 480
reg_y = 100

elements.append(make_text("regional_title", reg_x, reg_y,
                           "Regional Resources (per region)",
                           font_size=14, color="#495057", text_align="left"))

# Region frame
elements.append(make_rect("region_frame", reg_x, reg_y + 25, 420, 310,
                           bg="#f1f3f5", stroke_width=1,
                           stroke_style="dashed",
                           bound_elements=[{"id": "region_frame_lbl", "type": "text"}]))
elements.append(make_text("region_frame_lbl", reg_x + 5, reg_y + 28,
                           "for_each = var.regions", font_size=11,
                           color="#868e96", text_align="left",
                           container_id="region_frame"))

# GuardDuty
gd_y = reg_y + 55
elements.append(make_rect("guardduty", reg_x + 15, gd_y, 185, 50,
                           bg="#ffe3e3", roundness={"type": 3},
                           bound_elements=[
                               {"id": "guardduty_lbl", "type": "text"},
                               {"id": "arrow_gd_sns", "type": "arrow"},
                           ]))
elements.append(make_text("guardduty_lbl", reg_x + 15, gd_y,
                           "GuardDuty\nDetector + Features", font_size=12,
                           container_id="guardduty",
                           vertical_align="middle"))

# EventBridge
elements.append(make_rect("eventbridge", reg_x + 220, gd_y, 185, 50,
                           bg="#e5dbff", roundness={"type": 3},
                           bound_elements=[
                               {"id": "eventbridge_lbl", "type": "text"},
                               {"id": "arrow_eb_sns", "type": "arrow"},
                           ]))
elements.append(make_text("eventbridge_lbl", reg_x + 220, gd_y,
                           "EventBridge\nGuardDuty Findings", font_size=12,
                           container_id="eventbridge",
                           vertical_align="middle"))

# SNS Topic
sns_y = gd_y + 75
elements.append(make_rect("sns_topic", reg_x + 120, sns_y, 185, 50,
                           bg="#fff4e6", roundness={"type": 3},
                           bound_elements=[
                               {"id": "sns_lbl", "type": "text"},
                               {"id": "arrow_gd_sns", "type": "arrow"},
                               {"id": "arrow_eb_sns", "type": "arrow"},
                               {"id": "arrow_sns_email", "type": "arrow"},
                           ]))
elements.append(make_text("sns_lbl", reg_x + 120, sns_y,
                           "SNS Topic\n+ Email Subscription", font_size=12,
                           container_id="sns_topic",
                           vertical_align="middle"))

# EBS Encryption
ebs_y = sns_y + 75
elements.append(make_rect("ebs_enc", reg_x + 15, ebs_y, 120, 50,
                           bg="#ebfbee", roundness={"type": 3},
                           bound_elements=[{"id": "ebs_lbl", "type": "text"}]))
elements.append(make_text("ebs_lbl", reg_x + 15, ebs_y,
                           "EBS\nEncryption", font_size=12,
                           container_id="ebs_enc",
                           vertical_align="middle"))

# Access Analyzer
elements.append(make_rect("access_analyzer", reg_x + 155, ebs_y, 120, 50,
                           bg="#e5dbff", roundness={"type": 3},
                           bound_elements=[{"id": "aa_lbl", "type": "text"}]))
elements.append(make_text("aa_lbl", reg_x + 155, ebs_y,
                           "Access\nAnalyzer", font_size=12,
                           container_id="access_analyzer",
                           vertical_align="middle"))

# Default Security Group
elements.append(make_rect("default_sg", reg_x + 295, ebs_y, 120, 50,
                           bg="#ffe3e3", roundness={"type": 3},
                           bound_elements=[{"id": "sg_lbl", "type": "text"}]))
elements.append(make_text("sg_lbl", reg_x + 295, ebs_y,
                           "Default SG\n(deny all)", font_size=12,
                           container_id="default_sg",
                           vertical_align="middle"))

# CT VPC annotation
ct_y = ebs_y + 60
elements.append(make_text("ct_vpc_note", reg_x + 295, ct_y,
                           "CT VPCs", font_size=10,
                           color="#868e96", text_align="center"))

# ═══════════════════════════════════════════════════════════
# Arrows
# ═══════════════════════════════════════════════════════════

# GuardDuty -> EventBridge (findings flow)
elements.append(make_arrow("arrow_gd_eb",
                            reg_x + 200, gd_y + 25,
                            [[0, 0], [20, 0]],
                            start_id="guardduty",
                            end_id="eventbridge",
                            color="#495057"))

# EventBridge -> SNS
elements.append(make_arrow("arrow_eb_sns",
                            reg_x + 312, gd_y + 50,
                            [[0, 0], [0, 25]],
                            start_id="eventbridge",
                            end_id="sns_topic",
                            color="#495057"))

# SNS -> Email (outside the frame)
elements.append(make_arrow("arrow_sns_email",
                            reg_x + 212, sns_y + 50,
                            [[0, 0], [0, 40]],
                            start_id="sns_topic",
                            color="#495057"))

email_y = sns_y + 95
elements.append(make_ellipse("email_dest", reg_x + 165, email_y, 100, 40,
                              bg="#e9ecef",
                              bound_elements=[{"id": "email_lbl", "type": "text"}]))
elements.append(make_text("email_lbl", reg_x + 165, email_y,
                           "Email", font_size=12,
                           container_id="email_dest",
                           vertical_align="middle"))

# ═══════════════════════════════════════════════════════════
# Management Account (bottom)
# ═══════════════════════════════════════════════════════════

mgmt_y = 500

elements.append(make_rect("mgmt_frame", 60, mgmt_y, 380, 100,
                           bg="#f8f9fa", stroke_width=1,
                           stroke_style="dashed",
                           bound_elements=[{"id": "mgmt_frame_lbl", "type": "text"}]))
elements.append(make_text("mgmt_frame_lbl", 65, mgmt_y + 3,
                           "Management Account", font_size=11,
                           color="#868e96", text_align="left",
                           container_id="mgmt_frame"))

elements.append(make_rect("org_governance", 80, mgmt_y + 30, 200, 50,
                           bg="#d0ebff", roundness={"type": 3},
                           bound_elements=[
                               {"id": "org_gov_lbl", "type": "text"},
                               {"id": "arrow_assume", "type": "arrow"},
                           ]))
elements.append(make_text("org_gov_lbl", 80, mgmt_y + 30,
                           "org-governance\nLambda", font_size=12,
                           container_id="org_governance",
                           vertical_align="middle"))

# Arrow: Lambda -> InfraHouseLogRetention (assumes role)
elements.append(make_arrow("arrow_assume",
                            280, mgmt_y + 55,
                            [[0, 0], [0, -155]],
                            start_id="org_governance",
                            end_id="log_retention_role",
                            style="dashed",
                            color="#e67700"))

elements.append(make_text("assume_label", 285, mgmt_y - 60,
                           "sts:AssumeRole", font_size=10,
                           color="#e67700", text_align="left"))

# ═══════════════════════════════════════════════════════════
# Legend
# ═══════════════════════════════════════════════════════════

legend_x = 500
legend_y = mgmt_y + 10

elements.append(make_text("legend_title", legend_x, legend_y,
                           "Legend", font_size=14, color="#495057",
                           text_align="left"))

# Legend items
items = [
    ("#e7f5ff", "Account Settings"),
    ("#ebfbee", "Storage / Encryption"),
    ("#ffe3e3", "Security / Detection"),
    ("#e5dbff", "Monitoring / Analysis"),
    ("#fff4e6", "IAM / Notifications"),
]
for i, (color, label) in enumerate(items):
    ly = legend_y + 25 + i * 28
    elements.append(make_rect(f"legend_box_{i}", legend_x, ly, 18, 18,
                               bg=color, stroke_width=1))
    elements.append(make_text(f"legend_label_{i}", legend_x + 25, ly,
                               label, font_size=11, color="#495057",
                               text_align="left"))


# ═══════════════════════════════════════════════════════════
# Build the document
# ═══════════════════════════════════════════════════════════

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

output_path = "docs/assets/architecture.excalidraw"
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(doc, f, indent=2)
    f.write("\n")

# Verification
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
    print(f"Written to {output_path}")
