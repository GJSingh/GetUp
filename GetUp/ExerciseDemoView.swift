// Views/ExerciseDemoView.swift
import SwiftUI

// MARK: - Exercise Icons

struct ExerciseIcons {
    static func icon(for id: String) -> String {
        switch id {
        case "bicep_curl":          return "figure.strengthtraining.traditional"
        case "shoulder_press":      return "figure.arms.open"
        case "lateral_raise":       return "figure.arms.open"
        case "squat":               return "figure.squats"
        case "tricep_extension":    return "figure.strengthtraining.functional"
        case "warrior_one":         return "figure.yoga"
        case "warrior_two":         return "figure.yoga"
        case "tree_pose":           return "figure.yoga"
        case "downward_dog":        return "figure.flexibility"
        case "chair_pose":          return "figure.yoga"
        case "zumba_hip_shake":     return "figure.dance"
        case "bhangra_arm_pump":    return "figure.dance"
        case "salsa_side_step":     return "figure.dance"
        case "arm_wave":            return "figure.wave.3.right"
        case "jumping_jack_groove": return "figure.jumprope"
        case "body_roll":           return "figure.dance"
        case "bhangra_giddha_hands":return "hands.clap"
        case "latin_hip_sway":      return "figure.dance"
        case "chest_pop":           return "figure.strengthtraining.functional"
        case "full_body_groove":    return "figure.dance"
        default:                    return "figure.mixed.cardio"
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

// MARK: - Strength Figures

struct BicepCurlFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            let t=CGFloat(phase)
            let wrX = w*0.72 - w*0.05*t
            let wrY = h*0.62 - h*0.40*t
            let elX = w*0.70, elY = h*0.40
            limb(&ctx, w*0.46,h*0.58, w*0.40,h*0.78, lw, color, 0.42)
            limb(&ctx, w*0.40,h*0.78, w*0.39,h*0.95, lw*0.85, color, 0.42)
            limb(&ctx, w*0.54,h*0.58, w*0.60,h*0.78, lw, color)
            limb(&ctx, w*0.60,h*0.78, w*0.61,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.24, w*0.59,h*0.58, color)
            limb(&ctx, w*0.36,h*0.28, w*0.30,h*0.42, lw, color, 0.45)
            limb(&ctx, w*0.30,h*0.42, w*0.27,h*0.58, lw*0.85, color, 0.45)
            limb(&ctx, w*0.64,h*0.28, elX,elY, lw, color)
            limb(&ctx, elX,elY, wrX,wrY, lw*0.85, color)
            dumbbell(&ctx, wrX+s*0.04, wrY+s*0.03, s*0.036)
            if phase > 0.1 {
                var arc = Path()
                arc.addArc(center:CGPoint(x:elX,y:elY), radius:s*0.21,
                           startAngle:.degrees(80), endAngle:.degrees(80-Double(t)*68), clockwise:true)
                ctx.stroke(arc, with:.color(color.opacity(0.28)), style:StrokeStyle(lineWidth:2, dash:[4,3]))
            }
            joint(&ctx, elX,elY, s*0.032, color)
            joint(&ctx, wrX,wrY, s*0.026, .white)
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
            limb(&ctx, w*0.44,h*0.58, w*0.40,h*0.78, lw, color)
            limb(&ctx, w*0.40,h*0.78, w*0.39,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,h*0.58, w*0.60,h*0.78, lw, color)
            limb(&ctx, w*0.60,h*0.78, w*0.61,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.28, w*0.59,h*0.58, color)
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
            label(&ctx, phase>0.5 ? "Full extension! ✓" : "Press up ↑", w*0.50, h*0.87, color)
        }
    }
}

struct LateralRaiseFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            let t = CGFloat(phase)
            // Smooth up-down cycle: 0 = arms at sides, 1 = arms at shoulder height
            let armRaise = CGFloat(abs(sin(Double(t) * .pi)))
            let lEy = h*0.42 - armRaise*h*0.14
            let lWy = h*0.44 - armRaise*h*0.16
            let lEx = w*0.41 - s*0.16*armRaise
            let lWx = max(w*0.41 - s*0.36*armRaise, w*0.06)
            let rEy = lEy; let rWy = lWy
            let rEx = w*0.59 + s*0.16*armRaise
            let rWx = min(w*0.59 + s*0.36*armRaise, w*0.94)
            limb(&ctx, w*0.44,h*0.58, w*0.40,h*0.78, lw, color)
            limb(&ctx, w*0.40,h*0.78, w*0.39,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,h*0.58, w*0.60,h*0.78, lw, color)
            limb(&ctx, w*0.60,h*0.78, w*0.61,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.24, w*0.59,h*0.58, color)
            limb(&ctx, w*0.41,h*0.28, lEx,lEy, lw, color)
            limb(&ctx, lEx,lEy, lWx,lWy, lw*0.85, color)
            limb(&ctx, w*0.59,h*0.28, rEx,rEy, lw, color)
            limb(&ctx, rEx,rEy, rWx,rWy, lw*0.85, color)
            dumbbell(&ctx, lWx, lWy, s*0.034)
            dumbbell(&ctx, rWx, rWy, s*0.034)
            // Shoulder-height guide line appears as arms reach top
            if armRaise > 0.7 {
                let alpha = Double((armRaise - 0.7) / 0.3)
                var guide = Path()
                guide.move(to:CGPoint(x:w*0.05, y:lWy))
                guide.addLine(to:CGPoint(x:w*0.95, y:lWy))
                ctx.stroke(guide, with:.color(color.opacity(0.35*alpha)),
                           style:StrokeStyle(lineWidth:1.5, dash:[5,4]))
                if armRaise > 0.88 { label(&ctx, "Shoulder height ✓", w*0.50, lWy-14, color) }
            }
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
            if phase > 0.65 {
                var g=Path()
                g.move(to:CGPoint(x:w*0.08,y:hipY)); g.addLine(to:CGPoint(x:w*0.92,y:hipY))
                ctx.stroke(g, with:.color(color.opacity(0.28*Double(t))), style:StrokeStyle(lineWidth:1.5,dash:[5,4]))
                if phase > 0.80 { label(&ctx,"Parallel ✓",w*0.50,hipY-14,color) }
            }
            limb(&ctx, w*0.44,hipY, lKx,lKy, lw, color)
            limb(&ctx, lKx,lKy, w*0.38,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,hipY, rKx,rKy, lw, color)
            limb(&ctx, rKx,rKy, w*0.62,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41,torsoTopY, w*0.59,hipY, color)
            limb(&ctx, w*0.41,hipY-h*0.20, w*0.30,hipY-h*0.02, s*0.046, color)
            limb(&ctx, w*0.59,hipY-h*0.20, w*0.70,hipY-h*0.02, s*0.046, color)
            dumbbell(&ctx, w*0.27,hipY+h*0.03, s*0.034, vertical:true)
            dumbbell(&ctx, w*0.73,hipY+h*0.03, s*0.034, vertical:true)
            for pt in [(lKx,lKy),(rKx,rKy),(w*0.44,hipY),(w*0.56,hipY)] {
                joint(&ctx, pt.0,pt.1, s*0.032, color)
            }
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
            limb(&ctx, w*0.44,h*0.58, w*0.40,h*0.78, lw, color)
            limb(&ctx, w*0.40,h*0.78, w*0.39,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,h*0.58, w*0.60,h*0.78, lw, color)
            limb(&ctx, w*0.60,h*0.78, w*0.61,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.24, w*0.59,h*0.58, color)
            limb(&ctx, w*0.42,h*0.28, lEx,lEy, lw, color)
            limb(&ctx, lEx,lEy, w*0.44,lWy, lw*0.85, color)
            limb(&ctx, w*0.58,h*0.28, rEx,rEy, lw, color)
            limb(&ctx, rEx,rEy, w*0.56,rWy, lw*0.85, color)
            let dbY=(lWy+rWy)/2
            dumbbell(&ctx, w*0.50, dbY, s*0.050, vertical:true)
            joint(&ctx, lEx,lEy, s*0.034, .white)
            joint(&ctx, rEx,rEy, s*0.034, .white)
            label(&ctx, "Elbows stay fixed ↑", w*0.50, h*0.87, color)
            limb(&ctx, w*0.50,h*0.16, w*0.50,h*0.24, s*0.07, color)
            head(&ctx, w*0.50,h*0.10, s*0.08, color)
        }
    }
}

// MARK: - Yoga Figures

struct WarriorOneFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.056
            // BIG visible breathing: chest expands and arms float up/down clearly
            let breathCycle = CGFloat(sin(phase * .pi * 2))
            let breath    = breathCycle * s * 0.022       // torso width pulse
            let armFloat  = breathCycle * h * 0.055       // arms rise/fall visibly
            let headFloat = breathCycle * h * 0.018       // head follows breath
            limb(&ctx, w*0.52,h*0.55, w*0.64,h*0.74, lw, color, 0.45)
            limb(&ctx, w*0.64,h*0.74, w*0.70,h*0.94, lw*0.85, color, 0.45)
            limb(&ctx, w*0.48,h*0.55, w*0.34,h*0.72, lw, color)
            limb(&ctx, w*0.34,h*0.72, w*0.28,h*0.94, lw*0.85, color)
            label(&ctx, "90°", w*0.18, h*0.70, color, size:12)
            torso(&ctx, w*0.41-breath, h*0.26, w*0.59+breath, h*0.55, color)
            limb(&ctx, w*0.42,h*0.30, w*0.36,h*0.14+armFloat, lw, color)
            limb(&ctx, w*0.36,h*0.14+armFloat, w*0.40,h*0.02+armFloat, lw*0.85, color)
            limb(&ctx, w*0.58,h*0.30, w*0.64,h*0.14+armFloat, lw, color)
            limb(&ctx, w*0.64,h*0.14+armFloat, w*0.60,h*0.02+armFloat, lw*0.85, color)
            joint(&ctx, w*0.34,h*0.72, s*0.034, color)
            joint(&ctx, w*0.36,h*0.14+armFloat, s*0.028, color)
            joint(&ctx, w*0.64,h*0.14+armFloat, s*0.028, color)
            limb(&ctx, w*0.50,h*0.16+headFloat, w*0.50,h*0.26, s*0.07, color)
            head(&ctx, w*0.50,h*0.09+headFloat, s*0.08, color)
        }
    }
}

struct WarriorTwoFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.052
            let breath = CGFloat(sin(phase * .pi * 2))
            // Clearly visible arm extension on inhale (was 0.012, now 0.045)
            let armExt  = breath * w * 0.045
            let chestExp = abs(breath) * s * 0.020
            limb(&ctx, w*0.44,h*0.54, w*0.30,h*0.71, lw, color)
            limb(&ctx, w*0.30,h*0.71, w*0.22,h*0.94, lw*0.85, color)
            limb(&ctx, w*0.56,h*0.54, w*0.66,h*0.72, lw, color, 0.5)
            limb(&ctx, w*0.66,h*0.72, w*0.74,h*0.94, lw*0.85, color, 0.5)
            torso(&ctx, w*0.41-chestExp, h*0.26, w*0.59+chestExp, h*0.54, color)
            limb(&ctx, w*0.41,h*0.32, w*0.18-armExt,h*0.32, lw, color)
            limb(&ctx, w*0.18-armExt,h*0.32, max(w*0.03-armExt, w*0.01),h*0.32, lw*0.85, color)
            limb(&ctx, w*0.59,h*0.32, w*0.82+armExt,h*0.32, lw, color)
            limb(&ctx, w*0.82+armExt,h*0.32, min(w*0.97+armExt, w*0.99),h*0.32, lw*0.85, color)
            var g=Path()
            g.move(to:CGPoint(x:w*0.02,y:h*0.30)); g.addLine(to:CGPoint(x:w*0.98,y:h*0.30))
            ctx.stroke(g, with:.color(color.opacity(0.22)), style:StrokeStyle(lineWidth:1.5,dash:[5,4]))
            label(&ctx, "Arms parallel ✓", w*0.50,h*0.20, color)
            joint(&ctx, w*0.30,h*0.71, s*0.034, color)
            limb(&ctx, w*0.50,h*0.16, w*0.50,h*0.26, s*0.07, color)
            head(&ctx, w*0.50,h*0.10, s*0.08, color)
        }
    }
}

struct TreePoseFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            // Clearly visible balance sway (was 0.018 → 0.055)
            let sway     = CGFloat(sin(phase * .pi * 2)) * w * 0.055
            let armFloat = CGFloat(sin(phase * .pi * 2)) * h * 0.050
            var bal=Path()
            bal.move(to:CGPoint(x:w*0.52,y:h*0.16))
            bal.addLine(to:CGPoint(x:w*0.52,y:h*0.95))
            ctx.stroke(bal, with:.color(color.opacity(0.16)), style:StrokeStyle(lineWidth:1.5,dash:[4,5]))
            limb(&ctx, w*0.54+sway,h*0.56, w*0.54+sway,h*0.76, lw, color)
            limb(&ctx, w*0.54+sway,h*0.76, w*0.55+sway,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.48+sway,h*0.56, w*0.32+sway*0.5,h*0.65, lw, color)
            limb(&ctx, w*0.32+sway*0.5,h*0.65, w*0.43+sway*0.5,h*0.75, lw*0.85, color)
            torso(&ctx, w*0.41+sway,h*0.26, w*0.59+sway,h*0.56, color)
            limb(&ctx, w*0.42+sway,h*0.30, w*0.37+sway,h*0.14+armFloat, lw, color)
            limb(&ctx, w*0.37+sway,h*0.14+armFloat, w*0.46+sway,h*0.03+armFloat, lw*0.85, color)
            limb(&ctx, w*0.58+sway,h*0.30, w*0.63+sway,h*0.14+armFloat, lw, color)
            limb(&ctx, w*0.63+sway,h*0.14+armFloat, w*0.54+sway,h*0.03+armFloat, lw*0.85, color)
            joint(&ctx, w*0.32+sway*0.5,h*0.65, s*0.032, color)
            joint(&ctx, w*0.54+sway,h*0.76, s*0.032, color)
            limb(&ctx, w*0.50+sway,h*0.16, w*0.50+sway,h*0.26, s*0.07, color)
            head(&ctx, w*0.50+sway,h*0.10, s*0.08, color)
        }
    }
}

struct DownwardDogFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.052
            // Clearly visible hip pump (was 0.022 → 0.065)
            let hipPulse = CGFloat(sin(phase * .pi * 2)) * h * 0.065
            let hX=w*0.50, hY=h*0.14-hipPulse
            let lSx=w*0.36, lSy=h*0.36
            let lHx=w*0.18, lHy=h*0.76
            let lFx=w*0.30, lFy=h*0.90
            let lKx=w*0.34, lKy=h*0.58
            let rKx=w*0.66, rKy=h*0.58
            let rFx=w*0.70, rFy=h*0.90
            let rHx=w*0.82, rHy=h*0.76
            let rSx=w*0.64, rSy=h*0.36
            label(&ctx, "Hips HIGH ↑", w*0.50, h*0.04, color)
            limb(&ctx, hX,hY, lKx,lKy, lw, color)
            limb(&ctx, lKx,lKy, lFx,lFy, lw*0.85, color)
            limb(&ctx, hX,hY, rKx,rKy, lw, color, 0.55)
            limb(&ctx, rKx,rKy, rFx,rFy, lw*0.85, color, 0.55)
            limb(&ctx, hX,hY, lSx,lSy, lw*1.1, color)
            limb(&ctx, lSx,lSy, lHx,lHy, lw, color)
            limb(&ctx, rSx,rSy, rHx,rHy, lw, color, 0.55)
            for pt in [(hX,hY),(lKx,lKy),(rKx,rKy),(lSx,lSy)] {
                joint(&ctx, pt.0,pt.1, s*0.030, color)
            }
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
            // Clearly visible squat pulse (was 0.025 → 0.060)
            let sink     = CGFloat(abs(sin(phase * .pi * 2))) * h * 0.060
            let armFloat = CGFloat(sin(phase * .pi * 2)) * h * 0.050
            limb(&ctx, w*0.44,h*0.62+sink, w*0.38,h*0.80+sink*0.5, lw, color)
            limb(&ctx, w*0.38,h*0.80+sink*0.5, w*0.38,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,h*0.62+sink, w*0.62,h*0.80+sink*0.5, lw, color)
            limb(&ctx, w*0.62,h*0.80+sink*0.5, w*0.62,h*0.95, lw*0.85, color)
            var seat=Path()
            seat.move(to:CGPoint(x:w*0.28,y:h*0.68+sink*0.5))
            seat.addLine(to:CGPoint(x:w*0.72,y:h*0.68+sink*0.5))
            ctx.stroke(seat, with:.color(color.opacity(0.22)), style:StrokeStyle(lineWidth:2,dash:[6,5]))
            torso(&ctx, w*0.41,h*0.30, w*0.59,h*0.62+sink, color)
            limb(&ctx, w*0.42,h*0.34, w*0.34,h*0.18+armFloat, lw, color)
            limb(&ctx, w*0.34,h*0.18+armFloat, w*0.38,h*0.04+armFloat, lw*0.85, color)
            limb(&ctx, w*0.58,h*0.34, w*0.66,h*0.18+armFloat, lw, color)
            limb(&ctx, w*0.66,h*0.18+armFloat, w*0.62,h*0.04+armFloat, lw*0.85, color)
            joint(&ctx, w*0.38,h*0.80+sink*0.5, s*0.033, color)
            joint(&ctx, w*0.62,h*0.80+sink*0.5, s*0.033, color)
            limb(&ctx, w*0.50,h*0.18, w*0.50,h*0.30, s*0.07, color)
            head(&ctx, w*0.50,h*0.11, s*0.08, color)
        }
    }
}

// MARK: - Dance Figures

struct ZumbaHipShakeFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            let t=CGFloat(phase)
            let hipShift = sin(t * .pi * 2) * w * 0.06
            let lhx=w*0.46+hipShift, rHx=w*0.54+hipShift
            limb(&ctx, lhx,h*0.58, w*0.38+hipShift*0.5,h*0.78, lw, color, 0.6)
            limb(&ctx, w*0.38+hipShift*0.5,h*0.78, w*0.37,h*0.95, lw*0.85, color, 0.6)
            limb(&ctx, rHx,h*0.58, w*0.62+hipShift*0.5,h*0.77, lw, color)
            limb(&ctx, w*0.62+hipShift*0.5,h*0.77, w*0.63,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41+hipShift*0.4,h*0.26, w*0.59+hipShift*0.4,h*0.58, color)
            limb(&ctx, w*0.59+hipShift*0.4,h*0.36, w*0.76,h*0.40, lw, color)
            limb(&ctx, w*0.76,h*0.40, w*0.88,h*0.36, lw*0.85, color)
            limb(&ctx, w*0.41+hipShift*0.4,h*0.36, w*0.24,h*0.40, lw, color)
            limb(&ctx, w*0.24,h*0.40, w*0.12,h*0.36, lw*0.85, color)
            let glowAlpha = 0.08 + abs(Double(hipShift)/Double(w*0.06)) * 0.12
            ctx.fill(Path(ellipseIn:CGRect(x:w*0.40+hipShift*0.4,y:h*0.54,width:w*0.20,height:h*0.06)), with:.color(color.opacity(glowAlpha)))
            label(&ctx, abs(hipShift) > w*0.03 ? "Hip POP! 🌶️" : "Shift those hips →", w*0.50, h*0.87, color)
            limb(&ctx, w*0.50+hipShift*0.3,h*0.17, w*0.50+hipShift*0.3,h*0.26, s*0.07, color)
            head(&ctx, w*0.50+hipShift*0.3,h*0.10, s*0.08, color)
        }
    }
}

struct BhangraArmPumpFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.055
            let t=CGFloat(phase)
            let rightUp = t < 0.5
            let rightElY = rightUp ? h*0.14 : h*0.30
            let rightWrY = rightUp ? h*0.02 : h*0.22
            let leftElY  = rightUp ? h*0.30 : h*0.14
            let leftWrY  = rightUp ? h*0.22 : h*0.02
            let rightElX = rightUp ? w*0.70 : w*0.76
            let leftElX  = rightUp ? w*0.30 : w*0.24
            limb(&ctx, w*0.44,h*0.58, w*0.34,h*0.76, lw, color)
            limb(&ctx, w*0.34,h*0.76, w*0.30,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.56,h*0.58, w*0.66,h*0.76, lw, color)
            limb(&ctx, w*0.66,h*0.76, w*0.70,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.26, w*0.59,h*0.58, color)
            limb(&ctx, w*0.59,h*0.30, rightElX,rightElY, lw, color)
            limb(&ctx, rightElX,rightElY, w*0.66+(rightUp ? -0.04 : 0)*w, rightWrY, lw*0.85, color)
            limb(&ctx, w*0.41,h*0.30, leftElX,leftElY, lw, color)
            limb(&ctx, leftElX,leftElY, w*0.34+(rightUp ? 0 : 0.04)*w, leftWrY, lw*0.85, color)
            let activeWristX = rightUp ? w*0.62 : w*0.38
            for i in 0..<3 {
                let ox = activeWristX + CGFloat(i-1)*s*0.04
                ctx.stroke(Path { p in
                    p.move(to:CGPoint(x:ox, y:h*0.06))
                    p.addLine(to:CGPoint(x:ox, y:h*0.01))
                }, with:.color(color.opacity(0.5-Double(i)*0.15)), lineWidth:2)
            }
            label(&ctx, "Pump it! 🥁", w*0.50, h*0.87, color)
            limb(&ctx, w*0.50,h*0.17, w*0.50,h*0.26, s*0.07, color)
            head(&ctx, w*0.50,h*0.10, s*0.08, color)
        }
    }
}

struct SalsaStepFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            let t=CGFloat(phase)
            let sway = sin(t * .pi * 2) * w * 0.05
            let stepOut = abs(sin(t * .pi * 2))
            limb(&ctx, w*0.46+sway,h*0.58, w*0.30+sway*1.2,h*0.76, lw, color)
            limb(&ctx, w*0.30+sway*1.2,h*0.76, w*0.26+sway,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.54+sway,h*0.58, w*0.60+sway*0.6,h*0.76, lw, color, 0.6)
            limb(&ctx, w*0.60+sway*0.6,h*0.76, w*0.62,h*0.94, lw*0.85, color, 0.6)
            torso(&ctx, w*0.41+sway*0.6,h*0.26, w*0.59+sway*0.6,h*0.58, color)
            limb(&ctx, w*0.59+sway*0.6,h*0.32, w*0.75,h*0.28, lw, color)
            limb(&ctx, w*0.75,h*0.28, w*0.86,h*0.30, lw*0.85, color)
            limb(&ctx, w*0.41+sway*0.6,h*0.32, w*0.28,h*0.36, lw, color)
            limb(&ctx, w*0.28,h*0.36, w*0.20,h*0.32, lw*0.85, color)
            if stepOut > 0.4 {
                var arrow = Path()
                let dir: CGFloat = sway > 0 ? 1 : -1
                arrow.move(to:CGPoint(x:w*0.50+dir*w*0.08, y:h*0.70))
                arrow.addLine(to:CGPoint(x:w*0.50+dir*w*0.16, y:h*0.70))
                ctx.stroke(arrow, with:.color(color.opacity(0.5)), lineWidth:2)
            }
            label(&ctx, "Step & sway! 💃", w*0.50, h*0.87, color)
            limb(&ctx, w*0.50+sway*0.5,h*0.17, w*0.50+sway*0.5,h*0.26, s*0.07, color)
            head(&ctx, w*0.50+sway*0.5,h*0.10, s*0.08, color)
        }
    }
}

struct ArmWaveFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.052
            let t=Double(phase)
            let waveL = sin(t * .pi * 2) * h * 0.06
            let waveC = sin(t * .pi * 2 + 0.8) * h * 0.06
            let waveR = sin(t * .pi * 2 + 1.6) * h * 0.06
            limb(&ctx, w*0.46,h*0.58, w*0.42,h*0.77, lw, color)
            limb(&ctx, w*0.42,h*0.77, w*0.41,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.54,h*0.58, w*0.58,h*0.77, lw, color)
            limb(&ctx, w*0.58,h*0.77, w*0.59,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.25, w*0.59,h*0.58, color)
            let lShY = h*0.30 + CGFloat(waveL)
            let lElX = w*0.24, lElY = h*0.32 + CGFloat(waveC)
            let lWrX = w*0.08, lWrY = h*0.30 + CGFloat(waveR)
            limb(&ctx, w*0.41,lShY, lElX,lElY, lw, color)
            limb(&ctx, lElX,lElY, lWrX,lWrY, lw*0.85, color)
            joint(&ctx, lElX,lElY, s*0.030, color)
            let rShY = h*0.30 + CGFloat(waveR)
            let rElX = w*0.76, rElY = h*0.32 + CGFloat(waveC)
            let rWrX = w*0.92, rWrY = h*0.30 + CGFloat(waveL)
            limb(&ctx, w*0.59,rShY, rElX,rElY, lw, color)
            limb(&ctx, rElX,rElY, rWrX,rWrY, lw*0.85, color)
            joint(&ctx, rElX,rElY, s*0.030, color)
            var wavePath = Path()
            for i in 0...20 {
                let x = w*0.05 + CGFloat(i)/20.0 * w*0.90
                let y = h*0.28 + CGFloat(sin(t * .pi * 2 + Double(i)*0.3)) * h*0.04
                if i==0 { wavePath.move(to:CGPoint(x:x,y:y)) }
                else { wavePath.addLine(to:CGPoint(x:x,y:y)) }
            }
            ctx.stroke(wavePath, with:.color(color.opacity(0.22)), style:StrokeStyle(lineWidth:1.5,dash:[3,4]))
            label(&ctx, "Roll that wave 🌊", w*0.50, h*0.87, color)
            limb(&ctx, w*0.50,h*0.16, w*0.50,h*0.25, s*0.07, color)
            head(&ctx, w*0.50,h*0.09, s*0.08, color)
        }
    }
}

struct JumpClapFigure: View {
    var phase: Double; var color: Color

    private func drawBurst(_ ctx: inout GraphicsContext, centerX: CGFloat, centerY: CGFloat, size: CGFloat, t: Double) {
        let angles: [Double] = [0, 60, 120, 180, 240, 300]
        let burst = CGFloat(size * 0.06 * (1 - t))
        for angle in angles {
            let rad = angle * .pi / 180
            let x1 = centerX + cos(rad) * size * 0.03
            let y1 = centerY + sin(rad) * size * 0.03
            let x2 = centerX + cos(rad) * (burst + size * 0.03)
            let y2 = centerY + sin(rad) * (burst + size * 0.03)
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: x1, y: y1))
                p.addLine(to: CGPoint(x: x2, y: y2))
            }, with: .color(color.opacity(0.6)), lineWidth: 2)
        }
    }

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height, s = min(w, h), lw = s * 0.055
            let t = CGFloat(phase)
            let bounce = abs(sin(t * .pi)) * h * 0.06
            let bodyY = -bounce
            let spread = abs(sin(t * .pi)) * w * 0.14
            let groundContact = bounce < h * 0.015
            let clap = CGFloat(1.0 - abs(sin(Double(t) * .pi)) * 0.18)
            limb(&ctx, w*0.47, h*0.58+bodyY, w*0.36-spread, h*0.76+bodyY*0.3, lw, color)
            limb(&ctx, w*0.36-spread, h*0.76+bodyY*0.3, w*0.30-spread*0.5, h*0.93+bodyY*0.1, lw*0.85, color)
            limb(&ctx, w*0.53, h*0.58+bodyY, w*0.64+spread, h*0.76+bodyY*0.3, lw, color)
            limb(&ctx, w*0.64+spread, h*0.76+bodyY*0.3, w*0.70+spread*0.5, h*0.93+bodyY*0.1, lw*0.85, color)
            torso(&ctx, w*0.41, h*0.24+bodyY, w*0.59, h*0.58+bodyY, color)
            let lWrX = w*0.46 * clap + w*0.04
            let rWrX = w*0.54 / clap - w*0.04
            limb(&ctx, w*0.41, h*0.28+bodyY, w*0.36, h*0.14+bodyY, lw, color)
            limb(&ctx, w*0.36, h*0.14+bodyY, lWrX, h*0.03+bodyY, lw*0.85, color)
            limb(&ctx, w*0.59, h*0.28+bodyY, w*0.64, h*0.14+bodyY, lw, color)
            limb(&ctx, w*0.64, h*0.14+bodyY, rWrX, h*0.03+bodyY, lw*0.85, color)
            if !groundContact {
                drawBurst(&ctx, centerX: w*0.50, centerY: h*0.04+bodyY, size: s, t: Double(t))
            }
            let shadowH = h * 0.04 * CGFloat(1 - Double(bounce / (h * 0.1)))
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.25, y: h*0.94, width: w*0.50, height: max(0, shadowH))),
                     with: .color(color.opacity(0.06)))
            label(&ctx, groundContact ? "Jump! ⚡" : "Air! 🎉", w*0.50, h*0.89, color)
            limb(&ctx, w*0.50, h*0.16+bodyY, w*0.50, h*0.24+bodyY, s*0.07, color)
            head(&ctx, w*0.50, h*0.09+bodyY, s*0.08, color)
        }
    }
}

struct BodyRollFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.055
            let t=Double(phase)
            let chestPop = sin(t * .pi * 2) * w * 0.035
            let hipPop   = sin(t * .pi * 2 - 1.0) * w * 0.035
            limb(&ctx, w*0.46,h*0.58+CGFloat(hipPop)*0.3, w*0.42,h*0.77, lw, color)
            limb(&ctx, w*0.42,h*0.77, w*0.41,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.54,h*0.58+CGFloat(hipPop)*0.3, w*0.58,h*0.77, lw, color)
            limb(&ctx, w*0.58,h*0.77, w*0.59,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.41+CGFloat(chestPop),h*0.25, w*0.59+CGFloat(chestPop),h*0.55+CGFloat(hipPop)*0.5, color)
            limb(&ctx, w*0.59+CGFloat(chestPop),h*0.32, w*0.72+CGFloat(chestPop)*0.5,h*0.44, lw, color)
            limb(&ctx, w*0.72+CGFloat(chestPop)*0.5,h*0.44, w*0.70,h*0.57, lw*0.85, color)
            limb(&ctx, w*0.41+CGFloat(chestPop),h*0.32, w*0.28+CGFloat(chestPop)*0.5,h*0.44, lw, color)
            limb(&ctx, w*0.28+CGFloat(chestPop)*0.5,h*0.44, w*0.30,h*0.57, lw*0.85, color)
            var spinePath = Path()
            for i in 0...8 {
                let y = h*0.22 + CGFloat(i) * h*0.04
                let x = w*0.50 + CGFloat(sin(t * .pi * 2 - Double(i)*0.5)) * w*0.04
                if i==0 { spinePath.move(to:CGPoint(x:x,y:y)) }
                else { spinePath.addLine(to:CGPoint(x:x,y:y)) }
            }
            ctx.stroke(spinePath, with:.color(color.opacity(0.35)), lineWidth:3)
            label(&ctx, "Wave down ↓ 🔄", w*0.50, h*0.87, color)
            limb(&ctx, w*0.50+CGFloat(chestPop)*0.5,h*0.16, w*0.50+CGFloat(chestPop)*0.5,h*0.25, s*0.07, color)
            head(&ctx, w*0.50+CGFloat(chestPop)*0.5,h*0.09, s*0.08, color)
        }
    }
}

struct GiddhaFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.055
            let t=CGFloat(phase)
            let bounce = abs(sin(t * .pi * 2)) * h * 0.04
            let kneeY  = h*0.74 + bounce
            limb(&ctx, w*0.46,h*0.58, w*0.36,kneeY, lw, color)
            limb(&ctx, w*0.36,kneeY, w*0.33,h*0.94, lw*0.85, color)
            limb(&ctx, w*0.54,h*0.58, w*0.64,kneeY, lw, color)
            limb(&ctx, w*0.64,kneeY, w*0.67,h*0.94, lw*0.85, color)
            torso(&ctx, w*0.41,h*0.26, w*0.59,h*0.58, color)
            let clapSpread = abs(sin(t * .pi * 2 + .pi/2)) * w * 0.12
            let clapY = h*0.36 - bounce*0.5
            limb(&ctx, w*0.41,h*0.32, w*0.30-clapSpread,clapY, lw, color)
            limb(&ctx, w*0.30-clapSpread,clapY, w*0.44-clapSpread*0.3,h*0.40, lw*0.85, color)
            limb(&ctx, w*0.59,h*0.32, w*0.70+clapSpread,clapY, lw, color)
            limb(&ctx, w*0.70+clapSpread,clapY, w*0.56+clapSpread*0.3,h*0.40, lw*0.85, color)
            if clapSpread < w*0.03 {
                ctx.fill(Path(ellipseIn:CGRect(x:w*0.42,y:h*0.34,width:w*0.16,height:h*0.08)),
                         with:.color(color.opacity(0.30)))
            }
            label(&ctx, clapSpread < w*0.03 ? "CLAP! 🙌" : "Reach out →", w*0.50, h*0.87, color)
            limb(&ctx, w*0.50,h*0.17, w*0.50,h*0.26, s*0.07, color)
            head(&ctx, w*0.50,h*0.10, s*0.08, color)
        }
    }
}

struct LatinHipSwayFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            let t=Double(phase)
            let sway = sin(t * .pi * 2) * w * 0.055
            limb(&ctx, w*0.52+CGFloat(sway)*0.4,h*0.58, w*0.58+CGFloat(sway)*0.6,h*0.77, lw, color)
            limb(&ctx, w*0.58+CGFloat(sway)*0.6,h*0.77, w*0.60+CGFloat(sway)*0.4,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.48+CGFloat(sway)*0.4,h*0.58, w*0.42+CGFloat(sway)*0.5,h*0.77, lw, color, 0.7)
            limb(&ctx, w*0.42+CGFloat(sway)*0.5,h*0.77, w*0.40+CGFloat(sway)*0.3,h*0.95, lw*0.85, color, 0.7)
            torso(&ctx, w*0.42+CGFloat(sway)*0.5,h*0.26, w*0.60+CGFloat(sway)*0.5,h*0.58, color)
            limb(&ctx, w*0.60+CGFloat(sway)*0.5,h*0.34, w*0.74+CGFloat(sway)*0.3,h*0.40, lw, color)
            limb(&ctx, w*0.74+CGFloat(sway)*0.3,h*0.40, w*0.84,h*0.44, lw*0.85, color)
            limb(&ctx, w*0.42+CGFloat(sway)*0.5,h*0.34, w*0.28+CGFloat(sway)*0.2,h*0.40, lw, color)
            limb(&ctx, w*0.28+CGFloat(sway)*0.2,h*0.40, w*0.18,h*0.44, lw*0.85, color)
            var arc = Path()
            arc.addArc(center:CGPoint(x:w*0.50,y:h*0.62), radius:w*0.18,
                       startAngle:.degrees(180), endAngle:.degrees(0), clockwise:false)
            ctx.stroke(arc, with:.color(color.opacity(0.18)), style:StrokeStyle(lineWidth:1.5,dash:[4,4]))
            label(&ctx, "Sway & flow 🎵", w*0.50, h*0.87, color)
            limb(&ctx, w*0.51+CGFloat(sway)*0.4,h*0.17, w*0.51+CGFloat(sway)*0.4,h*0.26, s*0.07, color)
            head(&ctx, w*0.51+CGFloat(sway)*0.4,h*0.10, s*0.08, color)
        }
    }
}

struct ChestPopFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.054
            let t=Double(phase)
            let chestX = sin(t * .pi * 2) * w * 0.04
            let chestY = abs(sin(t * .pi * 2)) * h * (-0.01)
            limb(&ctx, w*0.46,h*0.58, w*0.42,h*0.77, lw, color)
            limb(&ctx, w*0.42,h*0.77, w*0.41,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.54,h*0.58, w*0.58,h*0.77, lw, color)
            limb(&ctx, w*0.58,h*0.77, w*0.59,h*0.95, lw*0.85, color)
            torso(&ctx, w*0.42+CGFloat(chestX),h*0.25+CGFloat(chestY),
                  w*0.60+CGFloat(chestX),h*0.56+CGFloat(chestY), color)
            limb(&ctx, w*0.60+CGFloat(chestX),h*0.32, w*0.72-CGFloat(chestX*0.5),h*0.40, lw, color)
            limb(&ctx, w*0.72-CGFloat(chestX*0.5),h*0.40, w*0.68,h*0.52, lw*0.85, color)
            limb(&ctx, w*0.42+CGFloat(chestX),h*0.32, w*0.30-CGFloat(chestX*0.5),h*0.40, lw, color)
            limb(&ctx, w*0.30-CGFloat(chestX*0.5),h*0.40, w*0.34,h*0.52, lw*0.85, color)
            if chestX > w*0.02 {
                for dy in [-s*0.04, 0.0, s*0.04] {
                    let midY = h*0.38 + CGFloat(chestY) + CGFloat(dy)
                    ctx.stroke(Path { p in
                        p.move(to:CGPoint(x:w*0.64, y:midY))
                        p.addLine(to:CGPoint(x:w*0.76, y:midY))
                    }, with:.color(color.opacity(0.55)), lineWidth:2)
                    ctx.fill(Path { p in
                        p.move(to:CGPoint(x:w*0.76, y:midY-s*0.02))
                        p.addLine(to:CGPoint(x:w*0.76, y:midY+s*0.02))
                        p.addLine(to:CGPoint(x:w*0.81, y:midY))
                        p.closeSubpath()
                    }, with:.color(color.opacity(0.55)))
                }
            }
            label(&ctx, chestX > w*0.02 ? "Pop! 💥" : "And back... →", w*0.50, h*0.87, color)
            limb(&ctx, w*0.51+CGFloat(chestX)*0.4,h*0.16, w*0.51+CGFloat(chestX)*0.4,h*0.25, s*0.07, color)
            head(&ctx, w*0.51+CGFloat(chestX)*0.4,h*0.09, s*0.08, color)
        }
    }
}

struct FullBodyGrooveFigure: View {
    var phase: Double; var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w=sz.width, h=sz.height, s=min(w,h), lw=s*0.055
            let t=Double(phase)
            let kneeLift = max(0, sin(t * .pi * 2)) * h * 0.12
            let armRaise = abs(sin(t * .pi * 2 + 0.5))
            limb(&ctx, w*0.54,h*0.58, w*0.60,h*0.76, lw, color)
            limb(&ctx, w*0.60,h*0.76, w*0.62,h*0.95, lw*0.85, color)
            limb(&ctx, w*0.46,h*0.58, w*0.36,h*0.68+CGFloat(kneeLift)*0.2, lw, color)
            limb(&ctx, w*0.36,h*0.68+CGFloat(kneeLift)*0.2, w*0.40,h*0.82-CGFloat(kneeLift), lw*0.85, color)
            torso(&ctx, w*0.41,h*0.24, w*0.59,h*0.58, color)
            let rElY = h*0.16 + CGFloat(1-armRaise)*h*0.14
            let rWrY = h*0.04 + CGFloat(1-armRaise)*h*0.16
            limb(&ctx, w*0.59,h*0.30, w*0.72,rElY, lw, color)
            limb(&ctx, w*0.72,rElY, w*0.80,rWrY, lw*0.85, color)
            limb(&ctx, w*0.41,h*0.32, w*0.26,h*0.38, lw, color)
            limb(&ctx, w*0.26,h*0.38, w*0.16,h*0.46, lw*0.85, color)
            if kneeLift > h*0.04 {
                joint(&ctx, w*0.36,h*0.68+CGFloat(kneeLift)*0.2, s*0.034, color)
            }
            if armRaise > 0.85 {
                let angles: [Double] = [0, 90, 180, 270]
                for angle in angles {
                    let rad = angle * .pi / 180
                    let x1 = w*0.80+cos(rad)*s*0.02
                    let y1 = rWrY+sin(rad)*s*0.02
                    let x2 = w*0.80+cos(rad)*s*0.05
                    let y2 = rWrY+sin(rad)*s*0.05
                    ctx.stroke(Path { p in
                        p.move(to:CGPoint(x:x1, y:y1))
                        p.addLine(to:CGPoint(x:x2, y:y2))
                    }, with:.color(color.opacity(0.7)), lineWidth:2)
                }
            }
            label(&ctx, kneeLift > h*0.05 ? "Just groove! 🎉" : "Feel the beat →", w*0.50, h*0.87, color)
            limb(&ctx, w*0.50,h*0.15, w*0.50,h*0.24, s*0.07, color)
            head(&ctx, w*0.50,h*0.09, s*0.08, color)
        }
    }
}

// MARK: - Exercise Figure Dispatcher (value-based, no binding needed)

private func exerciseFigure(id: String, phase: Double, color: Color) -> some View {
    Group {
        switch id {
        case "bicep_curl":          BicepCurlFigure(phase: phase, color: color)
        case "shoulder_press":      ShoulderPressFigure(phase: phase, color: color)
        case "lateral_raise":       LateralRaiseFigure(phase: phase, color: color)
        case "squat":               SquatFigure(phase: phase, color: color)
        case "tricep_extension":    TricepFigure(phase: phase, color: color)
        case "warrior_one":         WarriorOneFigure(phase: phase, color: color)
        case "warrior_two":         WarriorTwoFigure(phase: phase, color: color)
        case "tree_pose":           TreePoseFigure(phase: phase, color: color)
        case "downward_dog":        DownwardDogFigure(phase: phase, color: color)
        case "chair_pose":          ChairPoseFigure(phase: phase, color: color)
        case "zumba_hip_shake":     ZumbaHipShakeFigure(phase: phase, color: color)
        case "bhangra_arm_pump":    BhangraArmPumpFigure(phase: phase, color: color)
        case "salsa_side_step":     SalsaStepFigure(phase: phase, color: color)
        case "arm_wave":            ArmWaveFigure(phase: phase, color: color)
        case "jumping_jack_groove": JumpClapFigure(phase: phase, color: color)
        case "body_roll":           BodyRollFigure(phase: phase, color: color)
        case "bhangra_giddha_hands":GiddhaFigure(phase: phase, color: color)
        case "latin_hip_sway":      LatinHipSwayFigure(phase: phase, color: color)
        case "chest_pop":           ChestPopFigure(phase: phase, color: color)
        case "full_body_groove":    FullBodyGrooveFigure(phase: phase, color: color)
        default:                    BicepCurlFigure(phase: phase, color: color)
        }
    }
}

// MARK: - Animated Demo Container
// Uses TimelineView(.animation) — SwiftUI drives rendering every display frame
// from the very first frame. No Timer, no @State phase, no first-load blank.

struct AnimatedExerciseDemo: View {
    let exercise: ExerciseDefinition
    var size: CGFloat = 160

    // Epoch is recorded once at first appear so phase is 0→1 from that moment
    @State private var epoch: Date? = nil

    var accentColor: Color {
        switch exercise.category {
        case .yoga:   return Color(hex: "B57BFF")
        case .dance:  return Color(hex: "FF6B35")
        default:      return Color(hex: "00C896")
        }
    }

    private var cycleDuration: Double {
        switch exercise.id {
        case "warrior_one", "warrior_two",
             "tree_pose", "downward_dog", "chair_pose": return 3.5
        case "jumping_jack_groove":  return 0.9
        case "bhangra_arm_pump":     return 0.8
        case "zumba_hip_shake":      return 1.1
        case "body_roll":            return 1.6
        case "chest_pop":            return 0.9
        case "full_body_groove":     return 1.4
        case "latin_hip_sway":       return 2.0
        case "arm_wave":             return 1.8
        case "salsa_side_step":      return 1.2
        case "bhangra_giddha_hands": return 0.9
        case "bicep_curl":           return 1.4
        case "shoulder_press":       return 1.6
        case "squat":                return 2.0
        case "tricep_extension":     return 1.4
        case "lateral_raise":        return 1.8
        default:                     return 1.4
        }
    }

    var body: some View {
        // TimelineView drives the view at display refresh rate from frame 1.
        // No Timer, no @State phase variable, no async dispatch needed.
        TimelineView(.animation) { timeline in
            let phase: Double = {
                guard let e = epoch else { return 0.5 }   // mid-pose before epoch set
                let elapsed = timeline.date.timeIntervalSince(e)
                return elapsed.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
            }()

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(accentColor.opacity(0.06))
                    .frame(width: size, height: size)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
                    .frame(width: size, height: size)

                exerciseFigure(id: exercise.id, phase: phase, color: accentColor)
                    .frame(width: size * 0.86, height: size * 0.90)

                VStack {
                    HStack {
                        Spacer()
                        Text(exercise.isHoldPose ? "POSE" : "LIVE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(accentColor.opacity(0.15))
                            .cornerRadius(6).padding(8)
                    }
                    Spacer()
                }
                .frame(width: size, height: size)
            }
        }
        .onAppear {
            // Set epoch immediately — TimelineView starts ticking from frame 1
            epoch = Date()
        }
        .onDisappear {
            // Reset epoch so next open starts a fresh cycle from 0
            epoch = nil
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
                    Text("\(remaining)")
                        .font(.system(size:32, weight:.bold, design:.rounded)).foregroundColor(.white)
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

// MARK: - Exercise Detail Sheet

struct ExerciseDetailSheet: View {
    let exercise: ExerciseDefinition
    @Environment(\.dismiss) private var dismiss

    var musicCategory: WorkoutMusicCategory {
        switch exercise.category {
        case .yoga:   return .yoga
        case .dance:  return .dance
        default:      return .strength
        }
    }

    var accentColor: Color {
        switch exercise.category {
        case .yoga:   return Color(hex: "B57BFF")
        case .dance:  return Color(hex: "FF6B35")
        default:      return Color(hex: "00C896")
        }
    }

    var body: some View {
        ZStack {
            Color(hex:"0A0A0F").ignoresSafeArea()
            ScrollView(showsIndicators:false) {
                VStack(spacing:24) {
                    RoundedRectangle(cornerRadius:3).fill(Color(hex:"333350"))
                        .frame(width:40, height:4).padding(.top,12)

                    // TimelineView renders immediately — no skeleton needed
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

                    // ── Music ──────────────────────────────────────────────
                    MusicGenrePicker(category: musicCategory, accentColor: accentColor)
                        .padding(.horizontal,24)

                    Button(action:{ dismiss() }) {
                        Text("Got it — let's go!").font(.system(size:15, weight:.semibold)).foregroundColor(.black)
                            .frame(maxWidth:.infinity).frame(height:52).background(accentColor).cornerRadius(14)
                    }
                    .padding(.horizontal,24).padding(.bottom,40)
                }
            }
        }
        .onDisappear {
            // Stop music when demo sheet is dismissed (don't bleed into rest of app)
            AudioManager.shared.stop()
        }
    }

    var instructionsSection: some View {
        let steps = exerciseSteps(for: exercise.id)
        return VStack(alignment:.leading, spacing:10) {
            Text("HOW TO DO IT").font(.system(size:11, weight:.bold))
                .foregroundColor(Color(hex:"444460")).kerning(2)
                .frame(maxWidth:.infinity, alignment:.leading).padding(.horizontal,24)
            VStack(spacing:8) {
                ForEach(Array(steps.enumerated()), id:\.offset) { i, step in
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
        let result: [String]
        switch id {
        case "bicep_curl":
            result = ["Stand tall, feet hip-width, dumbbells at sides palms forward.",
                      "Pin upper arms to your torso — only forearms move.",
                      "Curl dumbbells toward shoulders, squeezing bicep at the top.",
                      "Lower slowly. That's one rep."]
        case "shoulder_press":
            result = ["Stand tall. Dumbbells at ear height, elbows at 90°.",
                      "Engage core — don't arch.",
                      "Press both dumbbells straight up until arms fully extend.",
                      "Lower slowly. That's one rep."]
        case "lateral_raise":
            result = ["Stand tall, dumbbells at sides, slight elbow bend.",
                      "Keeping torso still, raise both arms out to the sides.",
                      "Stop when arms are parallel to the floor.",
                      "Lower slowly. That's one rep."]
        case "squat":
            result = ["Feet hip-width, toes slightly out, dumbbells at sides.",
                      "Push hips back, bend knees — sitting into a chair.",
                      "Lower until thighs are parallel to the floor.",
                      "Drive through heels to stand. That's one rep."]
        case "tricep_extension":
            result = ["Hold one dumbbell overhead with both hands.",
                      "Keep elbows close to your head — they point at the ceiling.",
                      "Lower the dumbbell behind your head by bending elbows only.",
                      "Press back up. That's one rep."]
        case "warrior_one":
            result = ["Step one foot back 3-4 feet. Back foot turns out 45°.",
                      "Bend front knee to 90° — knee directly over ankle.",
                      "Square hips to face forward.",
                      "Raise both arms overhead, palms facing each other.",
                      "Hold and breathe for the full duration."]
        case "warrior_two":
            result = ["Stand wide, feet 3-4 feet apart. Turn right foot out 90°.",
                      "Bend right knee to 90° — knee tracks over ankle.",
                      "Extend both arms at shoulder height, parallel to floor.",
                      "Gaze over front fingertips. Keep torso upright.",
                      "Hold and breathe. Switch sides after."]
        case "tree_pose":
            result = ["Stand tall. Fix gaze on a still point.",
                      "Shift weight onto right foot.",
                      "Place left foot on inner right calf or thigh (never the knee).",
                      "Raise both arms overhead when balanced.",
                      "Hold then switch sides."]
        case "downward_dog":
            result = ["Start on all fours — hands under shoulders.",
                      "Tuck toes and lift hips toward the ceiling.",
                      "Straighten legs as much as possible.",
                      "Press hands into floor. Let head hang between arms.",
                      "Hold and breathe — inverted V shape."]
        case "chair_pose":
            result = ["Stand tall, feet together or hip-width.",
                      "Raise both arms overhead, biceps beside ears.",
                      "Bend knees and push hips back — invisible chair.",
                      "Weight in heels, torso slightly forward.",
                      "Hold as low as comfortable."]
        case "zumba_hip_shake":
            result = ["Stand with feet shoulder-width apart, knees slightly bent.",
                      "Shift your weight onto your right foot — let your right hip pop out.",
                      "Shift to the left foot — pop the left hip out. Find a rhythm.",
                      "Add your arms: hold them out to the sides at waist height, elbows soft.",
                      "Make the hip movement bigger and faster as you get comfortable.",
                      "Keep your upper body relaxed — the energy comes from the hips, not the shoulders."]
        case "bhangra_arm_pump":
            result = ["Stand with feet wider than shoulder-width — a strong Bhangra stance.",
                      "Raise your right arm straight overhead, elbow bent, fist loose.",
                      "Pump it up twice on the beat, then switch to the left arm.",
                      "Alternate: right up, right up, left up, left up — like a dhol beat.",
                      "Add a slight bounce in your knees with each pump.",
                      "Keep the energy high — chest up, big smile, arms punching the sky!"]
        case "salsa_side_step":
            result = ["Start with feet together, weight centred.",
                      "Step your left foot out to the side — shift your weight onto it.",
                      "Bring your right foot to meet the left (close step).",
                      "Now step your right foot out — shift weight, then close.",
                      "Keep the pattern: step out, close, step out, close.",
                      "Add a hip accent on each weight shift — let the hip drop naturally.",
                      "Arms: one arm slightly forward, one back — salsa frame position."]
        case "arm_wave":
            result = ["Stand tall, arms extended out to the sides at shoulder height.",
                      "Start the wave at your left shoulder — let it roll down to the elbow.",
                      "Continue through the wrist, then fingertips.",
                      "As it exits the left hand, let it enter the right hand and travel back up.",
                      "Practice slow first — one body part at a time.",
                      "Speed up gradually until it looks like a fluid, continuous wave.",
                      "Keep your body still — only the arms move."]
        case "jumping_jack_groove":
            result = ["Start standing, feet together, arms at sides.",
                      "Jump your feet out wide while raising both arms overhead.",
                      "Clap your hands together at the top of the jump.",
                      "Jump your feet back together, arms back to sides.",
                      "Find a steady rhythm — clap lands exactly as feet come together.",
                      "Add flair: throw your head back slightly on the clap!",
                      "Keep the bounce light — land softly on the balls of your feet."]
        case "body_roll":
            result = ["Stand with feet hip-width, knees slightly bent, arms relaxed.",
                      "Start the movement at your chest — push it forward.",
                      "Let the movement travel down: chest forward, then stomach, then hips.",
                      "As the hips come forward, your chest naturally pulls back.",
                      "The motion makes an S-curve travelling down your spine.",
                      "Practice in slow motion first — isolate each body part.",
                      "Gradually speed it up until it becomes one smooth, rolling wave."]
        case "bhangra_giddha_hands":
            result = ["Stand with feet hip-width apart, knees with a slight bounce.",
                      "Extend both arms out to your sides at shoulder height.",
                      "Bring both hands in to clap in front of your chest.",
                      "Extend back out, then clap again — find the rhythm.",
                      "Variation: clap overhead, then at chest, then at hip level.",
                      "Add the knee bounce — rise on the beat, sink on the clap.",
                      "Traditionally done in a group circle — enjoy the energy!"]
        case "latin_hip_sway":
            result = ["Stand with feet hip-width, soft bend in the knees.",
                      "Slowly shift your weight onto your right foot.",
                      "Let your right hip rise and push out to the side naturally.",
                      "Shift weight to the left — left hip rises and pushes out.",
                      "The movement should feel like drawing a slow figure-8 with your hips.",
                      "Keep your upper body still and tall — movement is all below the waist.",
                      "Arms hang loosely or float out to the sides for balance."]
        case "chest_pop":
            result = ["Stand tall, feet hip-width, arms relaxed at sides.",
                      "Isolate your chest — push it sharply forward.",
                      "Then pull it back to neutral, or even slightly back.",
                      "That's one pop — forward and back. Keep shoulders level.",
                      "Add rhythm: pop on every beat, rest on the off-beat.",
                      "Keep your hips and legs still — this is a chest-only isolation.",
                      "Once comfortable, try popping to the left and right as well."]
        case "full_body_groove":
            result = ["This is your free-style time — no strict steps!",
                      "Start with a simple knee bounce to find your rhythm.",
                      "Add arm movement — let them swing naturally with the beat.",
                      "Lift one knee on the strong beat for a step touch feel.",
                      "Mix in any move you know: hip shake, arm wave, chest pop.",
                      "The goal is to keep moving continuously for the full timer.",
                      "Don't think too hard — feel the music and let your body move!"]
        default:
            result = ["Follow the animated figure above."]
        }
        return result
    }
}
