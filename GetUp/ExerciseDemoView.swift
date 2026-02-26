// Views/ExerciseDemoView.swift
// All 10 exercise figures drawn with Canvas — coordinates verified visually.
// Strength figures animate; yoga figures are static poses.

import SwiftUI

// MARK: - Exercise Icons

struct ExerciseIcons {
    static func icon(for id: String) -> String {
        switch id {
        case "bicep_curl":       return "figure.strengthtraining.traditional"
        case "shoulder_press":   return "figure.arms.open"
        case "lateral_raise":    return "figure.arms.open"
        case "squat":            return "figure.squats"
        case "tricep_extension": return "figure.strengthtraining.functional"
        case "warrior_one":      return "figure.yoga"
        case "warrior_two":      return "figure.yoga"
        case "tree_pose":        return "figure.yoga"
        case "downward_dog":     return "figure.flexibility"
        case "chair_pose":       return "figure.yoga"
        default:                 return "figure.mixed.cardio"
        }
    }
}

// MARK: - Canvas Drawing Helpers

private func limb(_ ctx: inout GraphicsContext, _ ax: CGFloat, _ ay: CGFloat,
                  _ bx: CGFloat, _ by: CGFloat, _ w: CGFloat, _ color: Color, _ alpha: Double = 1) {
    let dx = bx-ax, dy = by-ay
    let len = sqrt(dx*dx+dy*dy)
    guard len > 1 else { return }
    let px = -dy/len*w/2, py = dx/len*w/2
    var path = Path()
    path.move(to: CGPoint(x:ax+px, y:ay+py))
    path.addLine(to: CGPoint(x:ax-px, y:ay-py))
    path.addLine(to: CGPoint(x:bx-px, y:by-py))
    path.addLine(to: CGPoint(x:bx+px, y:by+py))
    path.closeSubpath()
    // rounded end caps
    path.addEllipse(in: CGRect(x:ax-w/2, y:ay-w/2, width:w, height:w))
    path.addEllipse(in: CGRect(x:bx-w/2, y:by-w/2, width:w, height:w))
    var c = ctx; c.opacity = alpha
    c.fill(path, with: .color(color))
}

private func joint(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat,
                   _ r: CGFloat, _ color: Color, _ alpha: Double = 1) {
    var c = ctx; c.opacity = alpha
    c.fill(Path(ellipseIn: CGRect(x:x-r, y:y-r, width:r*2, height:r*2)), with:.color(color))
}

private func head(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat,
                  _ r: CGFloat, _ color: Color) {
    ctx.stroke(Path(ellipseIn: CGRect(x:x-r, y:y-r, width:r*2, height:r*2)),
               with:.color(color), lineWidth:r*0.28)
}

private func torso(_ ctx: inout GraphicsContext, _ x1: CGFloat, _ y1: CGFloat,
                   _ x2: CGFloat, _ y2: CGFloat, _ color: Color) {
    ctx.fill(Path(roundedRect: CGRect(x:x1, y:y1, width:x2-x1, height:y2-y1),
                  cornerRadius:8), with:.color(color))
}

private func dumbbell(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat,
                      _ size: CGFloat, vertical: Bool = false) {
    let bar = Color(hex:"9999AA"), plate = Color(hex:"606070")
    if vertical {
        ctx.fill(Path(roundedRect:CGRect(x:cx-size*0.38,y:cy-size,width:size*0.76,height:size*2),cornerRadius:size*0.2), with:.color(bar))
        ctx.fill(Path(ellipseIn:CGRect(x:cx-size*0.6,y:cy-size-size*0.55,width:size*1.2,height:size*1.0)), with:.color(plate))
        ctx.fill(Path(ellipseIn:CGRect(x:cx-size*0.6,y:cy+size-size*0.45,width:size*1.2,height:size*1.0)), with:.color(plate))
    } else {
        ctx.fill(Path(roundedRect:CGRect(x:cx-size,y:cy-size*0.38,width:size*2,height:size*0.76),cornerRadius:size*0.2), with:.color(bar))
        ctx.fill(Path(ellipseIn:CGRect(x:cx-size-size*0.55,y:cy-size*0.6,width:size*1.1,height:size*1.2)), with:.color(plate))
        ctx.fill(Path(ellipseIn:CGRect(x:cx+size-size*0.55,y:cy-size*0.6,width:size*1.1,height:size*1.2)), with:.color(plate))
    }
}

private func label(_ ctx: inout GraphicsContext, _ text: String, _ x: CGFloat, _ y: CGFloat,
                   _ color: Color, size: CGFloat = 11) {
    ctx.draw(Text(text).font(.system(size:size, weight:.bold)).foregroundColor(color),
             at:CGPoint(x:x, y:y))
}

// MARK: - Strength Figures (animated)

struct BicepCurlFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            let t=CGFloat(phase)
            let wrX = w*0.72 - w*0.05*t
            let wrY = h*0.62 - h*0.40*t
            let elX = w*0.70, elY = h*0.40
            // legs
            limb(&ctx, w*0.46,h*0.58, w*0.40,h*0.78, lw, color, 0.42)
            limb(&ctx, w*0.40,h*0.78, w*0.39,h*0.95, lw*0.85, color, 0.42)
            limb(&ctx, w*0.54,h*0.58, w*0.60,h*0.78, lw, color)
            limb(&ctx, w*0.60,h*0.78, w*0.61,h*0.95, lw*0.85, color)
            // torso
            torso(&ctx, w*0.41,h*0.24, w*0.59,h*0.58, color)
            // left arm (static, faded)
            limb(&ctx, w*0.36,h*0.28, w*0.30,h*0.42, lw, color, 0.45)
            limb(&ctx, w*0.30,h*0.42, w*0.27,h*0.58, lw*0.85, color, 0.45)
            // right arm (animated)
            limb(&ctx, w*0.64,h*0.28, elX,elY, lw, color)
            limb(&ctx, elX,elY, wrX,wrY, lw*0.85, color)
            // dumbbell
            dumbbell(&ctx, wrX+s*0.04, wrY+s*0.03, s*0.036)
            // motion arc
            if phase > 0.1 {
                var arc = Path()
                arc.addArc(center:CGPoint(x:elX,y:elY), radius:s*0.21,
                           startAngle:.degrees(80), endAngle:.degrees(80-Double(t)*68), clockwise:true)
                ctx.stroke(arc, with:.color(color.opacity(0.28)),
                           style:StrokeStyle(lineWidth:2, dash:[4,3]))
            }
            joint(&ctx, elX,elY, s*0.032, color)
            joint(&ctx, wrX,wrY, s*0.026, .white)
            // neck + head
            limb(&ctx, w*0.50,h*0.16, w*0.50,h*0.24, s*0.07, color)
            head(&ctx, w*0.50,h*0.09, s*0.08, color)
        }
    }
}

struct ShoulderPressFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            let t=Double(phase)
            func lp(_ a: CGFloat,_ b: CGFloat) -> CGFloat { a+(b-a)*CGFloat(t) }
            let lEx=lp(w*0.20,w*0.24), lEy=lp(h*0.34,h*0.16)
            let lWx=lp(w*0.22,w*0.30), lWy=lp(h*0.22,h*0.02)
            let rEx=lp(w*0.80,w*0.76), rEy=lEy
            let rWx=lp(w*0.78,w*0.70), rWy=lWy
            // legs
            limb(&ctx, w*0.44,h*0.58, w*0.40,h*0.78, lw, color)
            limb(&ctx, w*0.40,h*0.78, w*0.39,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,h*0.58, w*0.60,h*0.78, lw, color)
            limb(&ctx, w*0.60,h*0.78, w*0.61,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.28, w*0.59,h*0.58, color)
            // arms
            limb(&ctx, w*0.41,h*0.32, lEx,lEy, lw, color)
            limb(&ctx, lEx,lEy, lWx,lWy, lw*0.85, color)
            limb(&ctx, w*0.59,h*0.32, rEx,rEy, lw, color)
            limb(&ctx, rEx,rEy, rWx,rWy, lw*0.85, color)
            dumbbell(&ctx, lWx, lWy-s*0.025, s*0.034)
            dumbbell(&ctx, rWx, rWy-s*0.025, s*0.034)
            joint(&ctx, lEx,lEy, s*0.030, color)
            joint(&ctx, rEx,rEy, s*0.030, color)
            limb(&ctx, w*0.50,h*0.18, w*0.50,h*0.28, s*0.07, color)
            head(&ctx, w*0.50,h*0.11, s*0.08, color)
            label(&ctx, phase>0.5 ? "Full extension! ✓" : "Press up ↑",
                  w*0.50, h*0.87, color)
        }
    }
}

struct LateralRaiseFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            // arm reach capped so dumbbells stay inside frame
            let lEx=w*0.41-s*0.26, lEy=h*0.29
            let lWx=max(w*0.41-s*0.46, w*0.05), lWy=h*0.28
            let rEx=w*0.59+s*0.26, rEy=h*0.29
            let rWx=min(w*0.59+s*0.46, w*0.95), rWy=h*0.28
            // legs
            limb(&ctx, w*0.44,h*0.58, w*0.40,h*0.78, lw, color)
            limb(&ctx, w*0.40,h*0.78, w*0.39,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,h*0.58, w*0.60,h*0.78, lw, color)
            limb(&ctx, w*0.60,h*0.78, w*0.61,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.24, w*0.59,h*0.58, color)
            // arms sweep out
            limb(&ctx, w*0.41,h*0.28, lEx,lEy, lw, color)
            limb(&ctx, lEx,lEy, lWx,lWy, lw*0.85, color)
            limb(&ctx, w*0.59,h*0.28, rEx,rEy, lw, color)
            limb(&ctx, rEx,rEy, rWx,rWy, lw*0.85, color)
            dumbbell(&ctx, lWx, lWy, s*0.034)
            dumbbell(&ctx, rWx, rWy, s*0.034)
            // shoulder-height guide line
            var guide = Path()
            guide.move(to:CGPoint(x:w*0.06, y:h*0.28))
            guide.addLine(to:CGPoint(x:w*0.94, y:h*0.28))
            ctx.stroke(guide, with:.color(color.opacity(0.30)),
                       style:StrokeStyle(lineWidth:1.5, dash:[5,4]))
            label(&ctx, "Shoulder height ✓", w*0.50, h*0.20, color)
            joint(&ctx, lEx,lEy, s*0.030, color)
            joint(&ctx, rEx,rEy, s*0.030, color)
            limb(&ctx, w*0.50,h*0.15, w*0.50,h*0.24, s*0.07, color)
            head(&ctx, w*0.50,h*0.08, s*0.08, color)
        }
    }
}

struct SquatFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.058
            let t=CGFloat(phase)
            let hipY = h*0.52 + t*h*0.18
            let ko   = s*0.058*t
            let lKx=w*0.40-ko, lKy=hipY+h*0.22
            let rKx=w*0.60+ko, rKy=hipY+h*0.22
            let torsoTopY = hipY-h*0.30
            // depth guide
            if phase > 0.65 {
                var g=Path()
                g.move(to:CGPoint(x:w*0.08,y:hipY)); g.addLine(to:CGPoint(x:w*0.92,y:hipY))
                ctx.stroke(g, with:.color(color.opacity(0.28*Double(t))), style:StrokeStyle(lineWidth:1.5,dash:[5,4]))
                if phase > 0.80 { label(&ctx,"Parallel ✓",w*0.50,hipY-14,color) }
            }
            // legs
            limb(&ctx, w*0.44,hipY, lKx,lKy, lw, color)
            limb(&ctx, lKx,lKy, w*0.38,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,hipY, rKx,rKy, lw, color)
            limb(&ctx, rKx,rKy, w*0.62,h*0.95, lw*0.85, color)
            // torso attached to hips
            torso(&ctx, w*0.41,torsoTopY, w*0.59,hipY, color)
            // arms with dumbbells
            limb(&ctx, w*0.41,hipY-h*0.20, w*0.30,hipY-h*0.02, s*0.046, color)
            limb(&ctx, w*0.59,hipY-h*0.20, w*0.70,hipY-h*0.02, s*0.046, color)
            dumbbell(&ctx, w*0.27,hipY+h*0.03, s*0.034, vertical:true)
            dumbbell(&ctx, w*0.73,hipY+h*0.03, s*0.034, vertical:true)
            // joints
            for pt in [(lKx,lKy),(rKx,rKy),(w*0.44,hipY),(w*0.56,hipY)] {
                joint(&ctx, pt.0,pt.1, s*0.032, color)
            }
            // neck: short limb upward from torso top, head sits just above
            let neckLen = s*0.05
            limb(&ctx, w*0.50,torsoTopY, w*0.50,torsoTopY-neckLen, s*0.065, color)
            head(&ctx, w*0.50, torsoTopY-neckLen-s*0.082, s*0.076, color)
        }
    }
}

struct TricepFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            let t=CGFloat(phase)
            let lWy=h*0.30-t*h*0.26, rWy=lWy
            let lEx=w*0.40, lEy=h*0.13, rEx=w*0.60, rEy=h*0.13
            // legs
            limb(&ctx, w*0.44,h*0.58, w*0.40,h*0.78, lw, color)
            limb(&ctx, w*0.40,h*0.78, w*0.39,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,h*0.58, w*0.60,h*0.78, lw, color)
            limb(&ctx, w*0.60,h*0.78, w*0.61,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.24, w*0.59,h*0.58, color)
            // arms — elbows high, wrists move up
            limb(&ctx, w*0.42,h*0.28, lEx,lEy, lw, color)
            limb(&ctx, lEx,lEy, w*0.44,lWy, lw*0.85, color)
            limb(&ctx, w*0.58,h*0.28, rEx,rEy, lw, color)
            limb(&ctx, rEx,rEy, w*0.56,rWy, lw*0.85, color)
            // overhead dumbbell — larger so it reads clearly
            let dbY=(lWy+rWy)/2
            dumbbell(&ctx, w*0.50, dbY, s*0.050, vertical:true)
            // white elbow dots = teaching cue
            joint(&ctx, lEx,lEy, s*0.034, .white)
            joint(&ctx, rEx,rEy, s*0.034, .white)
            label(&ctx, "Elbows stay fixed ↑", w*0.50, h*0.87, color)
            limb(&ctx, w*0.50,h*0.16, w*0.50,h*0.24, s*0.07, color)
            head(&ctx, w*0.50,h*0.10, s*0.08, color)
        }
    }
}

// MARK: - Yoga Figures (static)

struct WarriorOneFigure: View {
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.056
            // back leg (faded)
            limb(&ctx, w*0.52,h*0.55, w*0.64,h*0.74, lw, color, 0.45)
            limb(&ctx, w*0.64,h*0.74, w*0.70,h*0.94, lw*0.85, color, 0.45)
            // front leg (bent 90°)
            limb(&ctx, w*0.48,h*0.55, w*0.34,h*0.72, lw, color)
            limb(&ctx, w*0.34,h*0.72, w*0.28,h*0.94, lw*0.85, color)
            label(&ctx, "90°", w*0.18, h*0.70, color, size:12)
            torso(&ctx, w*0.41,h*0.26, w*0.59,h*0.55, color)
            // arms overhead
            limb(&ctx, w*0.42,h*0.30, w*0.36,h*0.14, lw, color)
            limb(&ctx, w*0.36,h*0.14, w*0.40,h*0.02, lw*0.85, color)
            limb(&ctx, w*0.58,h*0.30, w*0.64,h*0.14, lw, color)
            limb(&ctx, w*0.64,h*0.14, w*0.60,h*0.02, lw*0.85, color)
            joint(&ctx, w*0.34,h*0.72, s*0.034, color)
            joint(&ctx, w*0.36,h*0.14, s*0.028, color)
            joint(&ctx, w*0.64,h*0.14, s*0.028, color)
            limb(&ctx, w*0.50,h*0.16, w*0.50,h*0.26, s*0.07, color)
            head(&ctx, w*0.50,h*0.10, s*0.08, color)
        }
    }
}

struct WarriorTwoFigure: View {
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.052
            // front leg bent
            limb(&ctx, w*0.44,h*0.54, w*0.30,h*0.71, lw, color)
            limb(&ctx, w*0.30,h*0.71, w*0.22,h*0.94, lw*0.85, color)
            // back leg (faded)
            limb(&ctx, w*0.56,h*0.54, w*0.66,h*0.72, lw, color, 0.5)
            limb(&ctx, w*0.66,h*0.72, w*0.74,h*0.94, lw*0.85, color, 0.5)
            torso(&ctx, w*0.41,h*0.26, w*0.59,h*0.54, color)
            // arms fully outstretched
            limb(&ctx, w*0.41,h*0.32, w*0.18,h*0.32, lw, color)
            limb(&ctx, w*0.18,h*0.32, w*0.03,h*0.32, lw*0.85, color)
            limb(&ctx, w*0.59,h*0.32, w*0.82,h*0.32, lw, color)
            limb(&ctx, w*0.82,h*0.32, w*0.97,h*0.32, lw*0.85, color)
            // guide line
            var g=Path(); g.move(to:CGPoint(x:w*0.02,y:h*0.30)); g.addLine(to:CGPoint(x:w*0.98,y:h*0.30))
            ctx.stroke(g, with:.color(color.opacity(0.22)), style:StrokeStyle(lineWidth:1.5,dash:[5,4]))
            label(&ctx, "Arms parallel ✓", w*0.50,h*0.20, color)
            joint(&ctx, w*0.30,h*0.71, s*0.034, color)
            limb(&ctx, w*0.50,h*0.16, w*0.50,h*0.26, s*0.07, color)
            head(&ctx, w*0.50,h*0.10, s*0.08, color)
        }
    }
}

struct TreePoseFigure: View {
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            // balance line
            var bal=Path(); bal.move(to:CGPoint(x:w*0.52,y:h*0.16)); bal.addLine(to:CGPoint(x:w*0.52,y:h*0.95))
            ctx.stroke(bal, with:.color(color.opacity(0.16)), style:StrokeStyle(lineWidth:1.5,dash:[4,5]))
            // standing leg
            limb(&ctx, w*0.54,h*0.56, w*0.54,h*0.76, lw, color)
            limb(&ctx, w*0.54,h*0.76, w*0.55,h*0.95, lw*0.85, color)
            // raised leg bent out
            limb(&ctx, w*0.48,h*0.56, w*0.32,h*0.65, lw, color)
            limb(&ctx, w*0.32,h*0.65, w*0.43,h*0.75, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.26, w*0.59,h*0.56, color)
            // arms in prayer
            limb(&ctx, w*0.42,h*0.30, w*0.37,h*0.14, lw, color)
            limb(&ctx, w*0.37,h*0.14, w*0.46,h*0.03, lw*0.85, color)
            limb(&ctx, w*0.58,h*0.30, w*0.63,h*0.14, lw, color)
            limb(&ctx, w*0.63,h*0.14, w*0.54,h*0.03, lw*0.85, color)
            joint(&ctx, w*0.32,h*0.65, s*0.032, color)
            joint(&ctx, w*0.54,h*0.76, s*0.032, color)
            limb(&ctx, w*0.50,h*0.16, w*0.50,h*0.26, s*0.07, color)
            head(&ctx, w*0.50,h*0.10, s*0.08, color)
        }
    }
}

struct DownwardDogFigure: View {
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.052
            let hX=w*0.50, hY=h*0.14          // hips (highest point)
            let lSx=w*0.36, lSy=h*0.36        // left shoulder
            let lHx=w*0.18, lHy=h*0.76        // left hand
            let lFx=w*0.30, lFy=h*0.90        // left foot
            let lKx=w*0.34, lKy=h*0.58        // left knee
            let rKx=w*0.66, rKy=h*0.58
            let rFx=w*0.70, rFy=h*0.90
            let rHx=w*0.82, rHy=h*0.76
            let rSx=w*0.64, rSy=h*0.36
            label(&ctx, "Hips HIGH ↑", w*0.50, h*0.06, color)
            // legs from hips down
            limb(&ctx, hX,hY, lKx,lKy, lw, color)
            limb(&ctx, lKx,lKy, lFx,lFy, lw*0.85, color)
            limb(&ctx, hX,hY, rKx,rKy, lw, color, 0.55)
            limb(&ctx, rKx,rKy, rFx,rFy, lw*0.85, color, 0.55)
            // spine (hip to shoulder)
            limb(&ctx, hX,hY, lSx,lSy, lw*1.1, color)
            // arms from shoulder to hand
            limb(&ctx, lSx,lSy, lHx,lHy, lw, color)
            limb(&ctx, rSx,rSy, rHx,rHy, lw, color, 0.55)
            // joints
            for pt in [(hX,hY),(lKx,lKy),(rKx,rKy),(lSx,lSy)] {
                joint(&ctx, pt.0,pt.1, s*0.030, color)
            }
            // head hangs between shoulders — small, centred, correct position
            let hdX = (lSx+rSx)/2
            let hdY = lSy + s*0.10
            head(&ctx, hdX, hdY, s*0.044, color)
        }
    }
}

struct ChairPoseFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.056
            // bent knees
            limb(&ctx, w*0.44,h*0.62, w*0.38,h*0.80, lw, color)
            limb(&ctx, w*0.38,h*0.80, w*0.38,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,h*0.62, w*0.62,h*0.80, lw, color)
            limb(&ctx, w*0.62,h*0.80, w*0.62,h*0.95, lw*0.85, color)
            // invisible chair line
            var seat=Path()
            seat.move(to:CGPoint(x:w*0.28,y:h*0.68)); seat.addLine(to:CGPoint(x:w*0.72,y:h*0.68))
            ctx.stroke(seat, with:.color(color.opacity(0.22)), style:StrokeStyle(lineWidth:2,dash:[6,5]))
            torso(&ctx, w*0.41,h*0.30, w*0.59,h*0.62, color)
            // arms overhead
            limb(&ctx, w*0.42,h*0.34, w*0.34,h*0.18, lw, color)
            limb(&ctx, w*0.34,h*0.18, w*0.38,h*0.04, lw*0.85, color)
            limb(&ctx, w*0.58,h*0.34, w*0.66,h*0.18, lw, color)
            limb(&ctx, w*0.66,h*0.18, w*0.62,h*0.04, lw*0.85, color)
            joint(&ctx, w*0.38,h*0.80, s*0.033, color)
            joint(&ctx, w*0.62,h*0.80, s*0.033, color)
            limb(&ctx, w*0.50,h*0.18, w*0.50,h*0.30, s*0.07, color)
            head(&ctx, w*0.50,h*0.11, s*0.08, color)
        }
    }
}

// MARK: - ExerciseFigure Dispatcher

struct ExerciseFigure: View {
    let exerciseID: String
    let accentColor: Color
    @Binding var animPhase: Double

    var body: some View {
        Group {
            switch exerciseID {
            case "bicep_curl":       BicepCurlFigure(phase: animPhase, color: accentColor)
            case "shoulder_press":   ShoulderPressFigure(phase: animPhase, color: accentColor)
            case "lateral_raise":    LateralRaiseFigure(phase: animPhase, color: accentColor)
            case "squat":            SquatFigure(phase: animPhase, color: accentColor)
            case "tricep_extension": TricepFigure(phase: animPhase, color: accentColor)
            case "warrior_one":      WarriorOneFigure(color: accentColor)
            case "warrior_two":      WarriorTwoFigure(color: accentColor)
            case "tree_pose":        TreePoseFigure(color: accentColor)
            case "downward_dog":     DownwardDogFigure(color: accentColor)
            case "chair_pose":       ChairPoseFigure(phase: animPhase, color: accentColor)
            default:                 BicepCurlFigure(phase: animPhase, color: accentColor)
            }
        }
    }
}

// MARK: - Animated Demo Container

struct AnimatedExerciseDemo: View {
    let exercise: ExerciseDefinition
    var size: CGFloat = 160
    @State private var animPhase: Double = 0

    var accentColor: Color {
        exercise.category == .yoga ? Color(hex: "B57BFF") : Color(hex: "00C896")
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(accentColor.opacity(0.06))
                .frame(width: size, height: size)
            RoundedRectangle(cornerRadius: 20)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
                .frame(width: size, height: size)
            ExerciseFigure(exerciseID: exercise.id, accentColor: accentColor, animPhase: $animPhase)
                .frame(width: size*0.86, height: size*0.90)
            VStack {
                HStack {
                    Spacer()
                    Text(exercise.isHoldPose ? "POSE" : "DEMO")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(accentColor.opacity(0.15)).cornerRadius(6).padding(8)
                }
                Spacer()
            }
            .frame(width: size, height: size)
        }
        .onAppear { startAnimation() }
        .onDisappear { animPhase = 0 }
    }

    private func startAnimation() {
        guard !exercise.isHoldPose else { return }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            animPhase = 1.0
        }
    }
}

// MARK: - Yoga Hold Timer

struct YogaHoldTimerView: View {
    let targetSeconds: Int
    @Binding var isActive: Bool
    var onComplete: () -> Void
    @State private var elapsed: Int = 0
    @State private var timer: Timer?
    var progress: Double { guard targetSeconds>0 else { return 0 }; return Double(elapsed)/Double(targetSeconds) }
    var remaining: Int { max(0, targetSeconds-elapsed) }
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().stroke(Color(hex:"1E1E2E"), lineWidth:8).frame(width:100, height:100)
                Circle().trim(from:0, to:progress)
                    .stroke(LinearGradient(colors:[Color(hex:"B57BFF"),Color(hex:"7B4FD8")],
                                           startPoint:.topLeading, endPoint:.bottomTrailing),
                            style:StrokeStyle(lineWidth:8, lineCap:.round))
                    .frame(width:100, height:100).rotationEffect(.degrees(-90))
                    .animation(.linear(duration:1), value:elapsed)
                VStack(spacing:2) {
                    Text("\(remaining)").font(.system(size:32, weight:.bold, design:.rounded)).foregroundColor(.white)
                        .contentTransition(.numericText(countsDown:true)).animation(.spring(response:0.3), value:remaining)
                    Text("secs").font(.system(size:10, weight:.medium)).foregroundColor(Color(hex:"666680"))
                }
            }
            Text(isActive ? "Hold the pose…" : "Ready to hold?")
                .font(.system(size:13, weight:.medium)).foregroundColor(Color(hex:"8888AA"))
            if isActive {
                Button(action:skipHold) {
                    Text("Skip").font(.system(size:12, weight:.medium)).foregroundColor(Color(hex:"B57BFF"))
                        .padding(.horizontal,16).padding(.vertical,6)
                        .background(Color(hex:"B57BFF").opacity(0.12)).cornerRadius(20)
                }
            }
        }
        .onChange(of:isActive) { _,v in v ? startTimer() : stopTimer() }
        .onDisappear { stopTimer() }
    }
    private func startTimer() {
        elapsed=0
        timer=Timer.scheduledTimer(withTimeInterval:1, repeats:true) { _ in
            elapsed += 1; if elapsed>=targetSeconds { stopTimer(); onComplete() }
        }
    }
    private func stopTimer() { timer?.invalidate(); timer=nil }
    private func skipHold() { stopTimer(); onComplete() }
}

// MARK: - Exercise Detail Sheet

struct ExerciseDetailSheet: View {
    let exercise: ExerciseDefinition
    @Environment(\.dismiss) private var dismiss
    @State private var showTimer = false
    var accentColor: Color { exercise.category == .yoga ? Color(hex:"B57BFF") : Color(hex:"00C896") }

    var body: some View {
        ZStack {
            Color(hex:"0A0A0F").ignoresSafeArea()
            ScrollView(showsIndicators:false) {
                VStack(spacing:24) {
                    RoundedRectangle(cornerRadius:3).fill(Color(hex:"333350"))
                        .frame(width:40, height:4).padding(.top,12)
                    AnimatedExerciseDemo(exercise:exercise, size:240)
                    VStack(spacing:8) {
                        HStack(spacing:10) {
                            Image(systemName:ExerciseIcons.icon(for:exercise.id))
                                .font(.system(size:28, weight:.medium)).foregroundColor(accentColor)
                            Text(exercise.name).font(.custom("Georgia-Bold", size:26)).foregroundColor(.white)
                        }
                        Text(exercise.muscleGroups.joined(separator:" · "))
                            .font(.system(size:13)).foregroundColor(accentColor)
                        Text(exercise.category.rawValue.uppercased())
                            .font(.system(size:10, weight:.bold)).foregroundColor(accentColor)
                            .padding(.horizontal,10).padding(.vertical,4)
                            .background(accentColor.opacity(0.12)).cornerRadius(20).padding(.top,2)
                    }
                    Text(exercise.description).font(.system(size:15)).foregroundColor(Color(hex:"AAAACC"))
                        .multilineTextAlignment(.center).padding(.horizontal,24)
                    if exercise.isHoldPose {
                        VStack(spacing:8) {
                            Text("HOLD TIMER PREVIEW").font(.system(size:11, weight:.bold))
                                .foregroundColor(Color(hex:"444460")).kerning(2)
                            Text("During your workout this timer counts down your hold")
                                .font(.system(size:12)).foregroundColor(Color(hex:"666680")).multilineTextAlignment(.center)
                            YogaHoldTimerView(targetSeconds:min(exercise.defaultReps,10), isActive:$showTimer) { showTimer=false }
                            Button(action:{ showTimer.toggle() }) {
                                Text(showTimer ? "Stop Preview" : "Preview Timer")
                                    .font(.system(size:13, weight:.semibold)).foregroundColor(accentColor)
                                    .padding(.horizontal,20).padding(.vertical,8)
                                    .background(accentColor.opacity(0.12)).cornerRadius(20)
                            }
                        }
                        .padding(16).background(Color(hex:"14141E")).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius:16).stroke(accentColor.opacity(0.2),lineWidth:1))
                        .padding(.horizontal,24)
                    }
                    instructionsSection
                    HStack(spacing:12) {
                        Image(systemName:"camera.viewfinder").font(.system(size:18)).foregroundColor(accentColor)
                        Text(exercise.cameraSetup).font(.system(size:13)).foregroundColor(Color(hex:"8888AA"))
                            .fixedSize(horizontal:false, vertical:true)
                    }
                    .padding(16).background(accentColor.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius:12).stroke(accentColor.opacity(0.2),lineWidth:1))
                    .cornerRadius(12).padding(.horizontal,24)
                    HStack(spacing:20) {
                        InfoPill(label:"Sets", value:"\(exercise.defaultSets)", color:accentColor)
                        InfoPill(label:exercise.isHoldPose ? "Hold (s)" : "Reps", value:"\(exercise.defaultReps)", color:accentColor)
                    }
                    Button(action:{ dismiss() }) {
                        Text("Got it — let's go!").font(.system(size:15, weight:.semibold)).foregroundColor(.black)
                            .frame(maxWidth:.infinity).frame(height:52).background(accentColor).cornerRadius(14)
                    }
                    .padding(.horizontal,24).padding(.bottom,40)
                }
            }
        }
        .onDisappear { showTimer=false }
    }

    var instructionsSection: some View {
        let steps = exerciseSteps(for:exercise.id)
        return VStack(alignment:.leading, spacing:10) {
            Text("HOW TO DO IT").font(.system(size:11, weight:.bold))
                .foregroundColor(Color(hex:"444460")).kerning(2)
                .frame(maxWidth:.infinity, alignment:.leading).padding(.horizontal,24)
            VStack(spacing:8) {
                ForEach(Array(steps.enumerated()), id:\.offset) { i,step in
                    HStack(alignment:.top, spacing:14) {
                        Text("\(i+1)").font(.system(size:12, weight:.bold)).foregroundColor(accentColor)
                            .frame(width:24, height:24).background(accentColor.opacity(0.12)).clipShape(Circle())
                        Text(step).font(.system(size:13)).foregroundColor(Color(hex:"AAAACC"))
                            .fixedSize(horizontal:false, vertical:true)
                        Spacer()
                    }.padding(.horizontal,24)
                }
            }
        }
    }

    func exerciseSteps(for id: String) -> [String] {
        switch id {
        case "bicep_curl":       return ["Stand tall, feet hip-width, dumbbells at sides palms forward.","Pin upper arms to your torso — only forearms move.","Curl dumbbells toward shoulders, squeezing bicep at the top.","Lower slowly. That's one rep."]
        case "shoulder_press":   return ["Stand tall. Dumbbells at ear height, elbows at 90°.","Engage core — don't arch.","Press both dumbbells straight up until arms fully extend.","Lower slowly. That's one rep."]
        case "lateral_raise":    return ["Stand tall, dumbbells at sides, slight elbow bend.","Keeping torso still, raise both arms out to the sides.","Stop when arms are parallel to the floor.","Lower slowly. That's one rep."]
        case "squat":            return ["Feet hip-width, toes slightly out, dumbbells at sides.","Push hips back, bend knees — sitting into a chair.","Lower until thighs are parallel to the floor.","Drive through heels to stand. That's one rep."]
        case "tricep_extension": return ["Hold one dumbbell overhead with both hands.","Keep elbows close to your head — they point at the ceiling.","Lower the dumbbell behind your head by bending elbows only.","Press back up. That's one rep."]
        case "warrior_one":      return ["Step one foot back 3-4 feet. Back foot turns out 45°.","Bend front knee to 90° — knee directly over ankle.","Square hips to face forward.","Raise both arms overhead, palms facing each other.","Hold and breathe for the full duration."]
        case "warrior_two":      return ["Stand wide, feet 3-4 feet apart. Turn right foot out 90°.","Bend right knee to 90° — knee tracks over ankle.","Extend both arms at shoulder height, parallel to floor.","Gaze over front fingertips. Keep torso upright.","Hold and breathe. Switch sides after."]
        case "tree_pose":        return ["Stand tall. Fix gaze on a still point.","Shift weight onto right foot.","Place left foot on inner right calf or thigh (never the knee).","Raise both arms overhead when balanced.","Hold then switch sides."]
        case "downward_dog":     return ["Start on all fours — hands under shoulders.","Tuck toes and lift hips toward the ceiling.","Straighten legs as much as possible.","Press hands into floor. Let head hang between arms.","Hold and breathe — inverted V shape."]
        case "chair_pose":       return ["Stand tall, feet together or hip-width.","Raise both arms overhead, biceps beside ears.","Bend knees and push hips back — invisible chair.","Weight in heels, torso slightly forward.","Hold as low as comfortable."]
        default:                 return ["Follow the animated figure above."]
        }
    }
}

// MARK: - Info Pill

struct InfoPill: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing:4) {
            Text(value).font(.system(size:22, weight:.bold, design:.rounded)).foregroundColor(.white)
            Text(label).font(.system(size:10, weight:.medium)).foregroundColor(Color(hex:"555570")).kerning(0.5)
        }
        .frame(width:100).padding(.vertical,14).background(Color(hex:"14141E")).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius:14).stroke(color.opacity(0.3),lineWidth:1))
    }
}
