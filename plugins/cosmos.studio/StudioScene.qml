import QtQuick
import qs.Commons
import qs.Commons as Commons

Item {
  id: root

  property bool compact: false
  property bool active: true
  property int totalCount: 0
  property int needsYouCount: 0
  property int workingCount: 0
  property int finishedCount: 0
  property var crewList: []
  property color accentColor: Commons.Color.accent
  signal agentClicked(string windowAddress)

  property real phase: 0.0
  property int hoveredSeat: -1

  readonly property var visibleCrew: {
    var src = root.crewList || []
    var out = []
    var limit = Math.min(src.length, 6)
    for (var i = 0; i < limit; i++) {
      out.push(src[i])
    }
    return out
  }

  function seatPosition(idx, count) {
    // Returns normalized { x, y, scale, tier } for exact 1..6 robots above the bottom card!
    if (count <= 1) {
      return { x: 0.50, y: 0.52, scale: 1.18, tier: "desk" }
    }
    if (count === 2) {
      var s2 = [
        { x: 0.33, y: 0.53, scale: 1.04, tier: "desk" },
        { x: 0.68, y: 0.53, scale: 1.04, tier: "desk" }
      ]
      return s2[idx]
    }
    if (count === 3) {
      var s3 = [
        { x: 0.27, y: 0.55, scale: 0.98, tier: "desk" },
        { x: 0.74, y: 0.55, scale: 0.98, tier: "desk" },
        { x: 0.50, y: 0.37, scale: 0.90, tier: "mezzanine" }
      ]
      return s3[idx]
    }
    if (count === 4) {
      var s4 = [
        { x: 0.28, y: 0.56, scale: 0.94, tier: "desk" },
        { x: 0.72, y: 0.56, scale: 0.94, tier: "desk" },
        { x: 0.36, y: 0.35, scale: 0.84, tier: "mezzanine" },
        { x: 0.66, y: 0.35, scale: 0.84, tier: "mezzanine" }
      ]
      return s4[idx]
    }
    if (count === 5) {
      var s5 = [
        { x: 0.22, y: 0.56, scale: 0.86, tier: "desk" },
        { x: 0.50, y: 0.57, scale: 0.88, tier: "desk" },
        { x: 0.78, y: 0.56, scale: 0.86, tier: "desk" },
        { x: 0.35, y: 0.34, scale: 0.80, tier: "mezzanine" },
        { x: 0.66, y: 0.34, scale: 0.80, tier: "mezzanine" }
      ]
      return s5[idx]
    }
    var s6 = [
      { x: 0.22, y: 0.56, scale: 0.84, tier: "desk" },
      { x: 0.50, y: 0.57, scale: 0.86, tier: "desk" },
      { x: 0.78, y: 0.56, scale: 0.84, tier: "desk" },
      { x: 0.24, y: 0.34, scale: 0.76, tier: "mezzanine" },
      { x: 0.50, y: 0.33, scale: 0.78, tier: "mezzanine" },
      { x: 0.76, y: 0.34, scale: 0.76, tier: "mezzanine" }
    ]
    return s6[idx % 6]
  }

  function brandPalette(agentName) {
    var n = String(agentName || "").toLowerCase()
    if (n.indexOf("antigravity") !== -1 || n === "agy") {
      return {
        kind: "antigravity",
        armorTop: "#eef2ff",
        armorMid: "#a5b4fc",
        armorDark: "#3730a3",
        trim: "#38bdf8",
        glow: "rgba(56, 189, 248, 0.55)"
      }
    }
    if (n.indexOf("claude") !== -1) {
      return {
        kind: "claude",
        armorTop: "#fff5eb",
        armorMid: "#f6ad85",
        armorDark: "#7c3aed",
        chestDark: "#6b2f22",
        trim: "#f97316",
        glow: "rgba(249, 115, 22, 0.52)"
      }
    }
    if (n.indexOf("chatgpt") !== -1 || n.indexOf("codex") !== -1 || n.indexOf("openai") !== -1) {
      return {
        kind: "openai",
        armorTop: "#ecfdf5",
        armorMid: "#99f6e4",
        armorDark: "#065f46",
        trim: "#10b981",
        glow: "rgba(16, 185, 129, 0.52)"
      }
    }
    if (n.indexOf("hermes") !== -1) {
      return {
        kind: "hermes",
        armorTop: "#fefce8",
        armorMid: "#fcd34d",
        armorDark: "#78350f",
        trim: "#f59e0b",
        glow: "rgba(245, 158, 11, 0.56)"
      }
    }
    return {
      kind: "cyber",
      armorTop: "#fef3c7",
      armorMid: "#fcd34d",
      armorDark: "#78350f",
      trim: "#f59e0b",
      glow: "rgba(245, 158, 11, 0.50)"
    }
  }

  Timer {
    // Adaptive FPS (friendly to CPU & TigerVNC bandwidth):
    // ~12 FPS while an agent is actively typing/asking, ~3.5 FPS gentle star twinkle when all agents are idle/finished
    interval: (root.workingCount > 0 || root.needsYouCount > 0) ? 85 : 280
    repeat: true
    running: root.active && root.visible
    onTriggered: {
      root.phase += (root.workingCount > 0 || root.needsYouCount > 0) ? 0.11 : 0.08
      loftCanvas.requestPaint()
    }
  }

  onCrewListChanged: loftCanvas.requestPaint()
  onTotalCountChanged: loftCanvas.requestPaint()
  onHoveredSeatChanged: loftCanvas.requestPaint()
  onWidthChanged: loftCanvas.requestPaint()
  onHeightChanged: loftCanvas.requestPaint()

  // 1. Real-Time GPU GLSL Cosmic & Cyberpunk Skyline Backdrop
  ShaderEffect {
    anchors.fill: parent
    fragmentShader: Qt.resolvedUrl("shaders/studio_sky.frag.qsb")
    property real uTime: root.phase
    property real uWorking: root.workingCount > 0 ? 1.0 : 0.15
    property vector4d uAccent: Qt.vector4d(root.accentColor.r, root.accentColor.g, root.accentColor.b, 1.0)
  }

  // 2. Architectural Cyber-Loft & Articulated Mecha Crew Canvas
  Canvas {
    id: loftCanvas
    anchors.fill: parent
    antialiasing: true

    function statusColor(status) {
      if (status === "needs_you") return "#fbbf24"
      if (status === "working") return "#38bdf8"
      return "#4ade80"
    }

    function drawMechaBot(ctx, cx, cy, unit, agent, idx, isHovered) {
      var name = agent ? String(agent.agentName || "Agent") : "Agent"
      var status = agent ? String(agent.status || "finished") : "finished"
      var pal = root.brandPalette(name)
      var stCol = statusColor(status)

      var t = root.phase + idx * 1.65
      var bob = (status === "working")
        ? Math.sin(t * 2.8) * (unit * 0.06)
        : Math.sin(t * 1.3) * (unit * 0.08)

      ctx.save()
      ctx.translate(cx, cy + bob)
      if (isHovered) {
        ctx.scale(1.07, 1.07)
      }

      // Hover aura / workstation backlight behind robot
      var aura = ctx.createRadialGradient(0, -unit * 0.1, unit * 0.15, 0, -unit * 0.1, unit * 1.45)
      aura.addColorStop(0.0, isHovered ? "rgba(255, 255, 255, 0.34)" : pal.glow)
      aura.addColorStop(1.0, "rgba(0, 0, 0, 0.0)")
      ctx.fillStyle = aura
      ctx.beginPath()
      ctx.arc(0, -unit * 0.1, unit * 1.45, 0, Math.PI * 2)
      ctx.fill()

      // Shadow / hover thruster ring on desk/platform
      ctx.save()
      ctx.translate(0, unit * 1.02 - bob * 0.6)
      ctx.scale(1.0, 0.26)
      ctx.fillStyle = "rgba(8, 10, 18, 0.68)"
      ctx.beginPath()
      ctx.arc(0, 0, unit * 0.88, 0, Math.PI * 2)
      ctx.fill()
      ctx.strokeStyle = stCol
      ctx.lineWidth = 2.2
      ctx.beginPath()
      ctx.arc(0, 0, unit * 0.62, 0, Math.PI * 2)
      ctx.stroke()
      ctx.restore()

      // --- ARMORED TORSO & PAULDRONS ---
      var torsoW = unit * 1.10
      var torsoH = unit * 0.66
      var torsoY = unit * 0.28

      // Shoulder pauldrons
      ctx.fillStyle = pal.armorMid
      ctx.strokeStyle = "#181c28"
      ctx.lineWidth = 1.6
      ctx.beginPath()
      ctx.arc(-torsoW * 0.50, torsoY + unit * 0.16, unit * 0.22, 0, Math.PI * 2)
      ctx.arc(torsoW * 0.50, torsoY + unit * 0.16, unit * 0.22, 0, Math.PI * 2)
      ctx.fill()
      ctx.stroke()

      // Main chamfered torso armor
      var torsoGrad = ctx.createLinearGradient(-torsoW * 0.5, torsoY, torsoW * 0.5, torsoY + torsoH)
      torsoGrad.addColorStop(0.0, pal.armorTop)
      torsoGrad.addColorStop(0.55, pal.armorMid)
      torsoGrad.addColorStop(1.0, "#283044")
      ctx.fillStyle = torsoGrad
      ctx.beginPath()
      ctx.roundedRect(-torsoW * 0.46, torsoY, torsoW * 0.92, torsoH, unit * 0.22, unit * 0.22)
      ctx.fill()
      ctx.strokeStyle = "rgba(15, 20, 32, 0.78)"
      ctx.lineWidth = 1.6
      ctx.stroke()

      // Dark armored chest plate + glowing Arc-Reactor Core
      ctx.fillStyle = "#141926"
      ctx.beginPath()
      ctx.roundedRect(-torsoW * 0.28, torsoY + unit * 0.11, torsoW * 0.56, torsoH * 0.56, unit * 0.10, unit * 0.10)
      ctx.fill()

      var corePulse = 0.78 + 0.22 * Math.sin(t * 3.2)
      ctx.fillStyle = pal.trim
      ctx.globalAlpha = corePulse
      ctx.beginPath()
      ctx.arc(0, torsoY + unit * 0.29, unit * 0.12, 0, Math.PI * 2)
      ctx.fill()
      ctx.globalAlpha = 1.0
      ctx.fillStyle = "#ffffff"
      ctx.beginPath()
      ctx.arc(0, torsoY + unit * 0.29, unit * 0.05, 0, Math.PI * 2)
      ctx.fill()

      // Neck joint
      ctx.fillStyle = "#1d2333"
      ctx.fillRect(-unit * 0.20, unit * 0.14, unit * 0.40, unit * 0.18)

      // --- BRAND HEADGEAR BEHIND/ABOVE HELMET ---
      if (pal.kind === "antigravity") {
        // Levitating glowing cyan/indigo anti-gravity halo ring above helmet!
        ctx.save()
        ctx.translate(0, -unit * 1.02 + Math.sin(t * 2.2) * 2.5)
        ctx.scale(1.0, 0.30)
        ctx.strokeStyle = "#38bdf8"
        ctx.lineWidth = 4.0
        ctx.beginPath()
        ctx.arc(0, 0, unit * 0.56, 0, Math.PI * 2)
        ctx.stroke()
        ctx.strokeStyle = "#ffffff"
        ctx.lineWidth = 1.4
        ctx.stroke()
        ctx.restore()
      } else if (pal.kind === "openai") {
        // Pointed cyber-fox sensor ears with glowing emerald inner panels!
        var earSide = [-1, 1]
        for (var e = 0; e < 2; e++) {
          var sgn = earSide[e]
          ctx.fillStyle = "#1f2937"
          ctx.beginPath()
          ctx.moveTo(sgn * unit * 0.34, -unit * 0.72)
          ctx.lineTo(sgn * unit * 0.68, -unit * 1.14)
          ctx.lineTo(sgn * unit * 0.72, -unit * 0.54)
          ctx.closePath()
          ctx.fill()

          ctx.fillStyle = pal.trim
          ctx.beginPath()
          ctx.moveTo(sgn * unit * 0.42, -unit * 0.73)
          ctx.lineTo(sgn * unit * 0.62, -unit * 1.02)
          ctx.lineTo(sgn * unit * 0.64, -unit * 0.60)
          ctx.closePath()
          ctx.fill()
        }
      } else if (pal.kind === "hermes") {
        // Iconic Olympian golden winged Hermes helmet (cyber-feather wings on both sides!)
        var wingFlap = Math.sin(t * 3.0) * 0.09
        for (var wSide = -1; wSide <= 1; wSide += 2) {
          ctx.save()
          ctx.translate(wSide * unit * 0.72, -unit * 0.52)
          ctx.rotate(wSide * (-0.08 + wingFlap))

          // Outer primary golden feather sweeping wide past helmet & badge
          ctx.fillStyle = "#fbbf24"
          ctx.strokeStyle = "#78350f"
          ctx.lineWidth = 1.5
          ctx.beginPath()
          ctx.moveTo(0, 0)
          ctx.quadraticCurveTo(wSide * unit * 0.56, -unit * 0.44, wSide * unit * 0.88, -unit * 0.34)
          ctx.quadraticCurveTo(wSide * unit * 0.58, -unit * 0.04, wSide * unit * 0.14, unit * 0.12)
          ctx.closePath()
          ctx.fill()
          ctx.stroke()

          // Inner bright white-gold secondary feather
          ctx.fillStyle = "#fef9c3"
          ctx.beginPath()
          ctx.moveTo(wSide * unit * 0.06, -unit * 0.02)
          ctx.quadraticCurveTo(wSide * unit * 0.42, -unit * 0.28, wSide * unit * 0.66, -unit * 0.18)
          ctx.quadraticCurveTo(wSide * unit * 0.42, unit * 0.02, wSide * unit * 0.12, unit * 0.06)
          ctx.closePath()
          ctx.fill()
          ctx.restore()
        }
      } else {
        // Twin expressive spring antennae with glowing tips (Claude / Cyber)
        var antWiggle = (status === "needs_you") ? Math.sin(t * 5.0) * 0.18 : Math.sin(t * 1.8) * 0.06
        for (var a = -1; a <= 1; a += 2) {
          ctx.save()
          ctx.rotate(antWiggle * a)
          ctx.strokeStyle = "#cbd5e1"
          ctx.lineWidth = 2.2
          ctx.beginPath()
          ctx.moveTo(a * unit * 0.32, -unit * 0.76)
          ctx.lineTo(a * unit * 0.46, -unit * 1.08)
          ctx.stroke()

          ctx.fillStyle = pal.trim
          ctx.beginPath()
          ctx.arc(a * unit * 0.46, -unit * 1.11, unit * 0.10, 0, Math.PI * 2)
          ctx.fill()
          ctx.restore()
        }
      }

      // --- OVER-EAR STUDIO HEADPHONES / SIDE COMMS PODS ---
      // Headphone headband arch
      if (pal.kind === "claude" || pal.kind === "cyber") {
        ctx.strokeStyle = "#334155"
        ctx.lineWidth = unit * 0.11
        ctx.beginPath()
        ctx.arc(0, -unit * 0.28, unit * 0.86, Math.PI * 1.08, Math.PI * 1.92)
        ctx.stroke()
      }

      for (var hp = -1; hp <= 1; hp += 2) {
        ctx.fillStyle = "#1e2536"
        ctx.beginPath()
        ctx.roundedRect(hp * unit * 0.74 - unit * 0.14, -unit * 0.46, unit * 0.28, unit * 0.46, unit * 0.10, unit * 0.10)
        ctx.fill()
        ctx.strokeStyle = pal.trim
        ctx.lineWidth = 2.0
        ctx.stroke()
      }

      // --- CHAMFERED MECHA HELMET ---
      var headW = unit * 1.54
      var headH = unit * 1.06
      var headX = -headW * 0.5
      var headY = -unit * 0.82

      var headGrad = ctx.createLinearGradient(headX, headY, headX + headW * 0.8, headY + headH)
      headGrad.addColorStop(0.0, "#ffffff")
      headGrad.addColorStop(0.28, pal.armorTop)
      headGrad.addColorStop(0.78, pal.armorMid)
      headGrad.addColorStop(1.0, "#475569")

      ctx.fillStyle = headGrad
      ctx.beginPath()
      ctx.roundedRect(headX, headY, headW, headH, unit * 0.36, unit * 0.36)
      ctx.fill()
      ctx.strokeStyle = "#171c29"
      ctx.lineWidth = 1.8
      ctx.stroke()

      // Forehead brand crest jewel
      ctx.fillStyle = pal.trim
      ctx.beginPath()
      ctx.moveTo(0, headY + unit * 0.08)
      ctx.lineTo(unit * 0.13, headY + unit * 0.18)
      ctx.lineTo(0, headY + unit * 0.25)
      ctx.lineTo(-unit * 0.13, headY + unit * 0.18)
      ctx.closePath()
      ctx.fill()

      // --- WIDE GLOSSY CURVED OLED VISOR ---
      var visorW = headW * 0.80
      var visorH = headH * 0.58
      var visorX = -visorW * 0.5
      var visorY = headY + unit * 0.30

      ctx.fillStyle = "#090d16"
      ctx.beginPath()
      ctx.roundedRect(visorX, visorY, visorW, visorH, unit * 0.22, unit * 0.22)
      ctx.fill()
      ctx.strokeStyle = "rgba(255, 255, 255, 0.22)"
      ctx.lineWidth = 1.3
      ctx.stroke()

      // Expressive LED Eyes & Cheek Blush inside OLED Visor
      var eyeY = visorY + visorH * 0.48
      var eyeSep = visorW * 0.24

      ctx.fillStyle = stCol
      ctx.strokeStyle = stCol
      ctx.lineWidth = Math.max(2.4, unit * 0.11)
      ctx.lineCap = "round"

      if (status === "needs_you") {
        // Wide curious amber eyes + raised brow
        ctx.beginPath()
        ctx.arc(-eyeSep, eyeY, unit * 0.14, 0, Math.PI * 2)
        ctx.arc(eyeSep, eyeY, unit * 0.11, 0, Math.PI * 2)
        ctx.fill()
        // Tiny white eye sparkle
        ctx.fillStyle = "#ffffff"
        ctx.beginPath()
        ctx.arc(-eyeSep - unit * 0.04, eyeY - unit * 0.04, unit * 0.045, 0, Math.PI * 2)
        ctx.arc(eyeSep - unit * 0.03, eyeY - unit * 0.03, unit * 0.04, 0, Math.PI * 2)
        ctx.fill()
      } else if (status === "working") {
        // Determined glowing cyber-visor eyes + animated data scanline
        ctx.beginPath()
        ctx.roundedRect(-eyeSep - unit * 0.16, eyeY - unit * 0.08, unit * 0.32, unit * 0.15, unit * 0.06, unit * 0.06)
        ctx.roundedRect(eyeSep - unit * 0.16, eyeY - unit * 0.08, unit * 0.32, unit * 0.15, unit * 0.06, unit * 0.06)
        ctx.fill()

        // Animated mini waveform mouth while working
        ctx.lineWidth = 1.6
        ctx.beginPath()
        var mw = unit * 0.22
        ctx.moveTo(-mw, eyeY + unit * 0.16)
        ctx.lineTo(-mw * 0.3, eyeY + unit * 0.16 - Math.abs(Math.sin(t * 5.0)) * unit * 0.08)
        ctx.lineTo(mw * 0.3, eyeY + unit * 0.16 + Math.abs(Math.cos(t * 5.0)) * unit * 0.06)
        ctx.lineTo(mw, eyeY + unit * 0.16)
        ctx.stroke()
      } else {
        // Cheerful ^ ^ arcs + cute smile + soft cheek glow
        ctx.beginPath()
        ctx.arc(-eyeSep, eyeY + unit * 0.04, unit * 0.14, Math.PI * 1.15, Math.PI * 1.85)
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(eyeSep, eyeY + unit * 0.04, unit * 0.14, Math.PI * 1.15, Math.PI * 1.85)
        ctx.stroke()

        ctx.lineWidth = Math.max(1.8, unit * 0.07)
        ctx.beginPath()
        ctx.arc(0, eyeY + unit * 0.09, unit * 0.09, Math.PI * 0.15, Math.PI * 0.85)
        ctx.stroke()

        ctx.fillStyle = "rgba(244, 114, 182, 0.35)"
        ctx.beginPath()
        ctx.arc(-eyeSep * 1.35, eyeY + unit * 0.12, unit * 0.07, 0, Math.PI * 2)
        ctx.arc(eyeSep * 1.35, eyeY + unit * 0.12, unit * 0.07, 0, Math.PI * 2)
        ctx.fill()
      }

      // Diagonal glass gleam on visor
      ctx.fillStyle = "rgba(255, 255, 255, 0.16)"
      ctx.beginPath()
      ctx.moveTo(visorX + unit * 0.12, visorY + unit * 0.05)
      ctx.lineTo(visorX + unit * 0.42, visorY + unit * 0.05)
      ctx.lineTo(visorX + unit * 0.24, visorY + visorH - unit * 0.05)
      ctx.lineTo(visorX + unit * 0.06, visorY + visorH - unit * 0.05)
      ctx.closePath()
      ctx.fill()

      // --- ARTICULATED ARMS & LIVE ACTION PROPS ---
      if (status === "working") {
        // Glowing angled holographic keyboard + rapid typing hands + rising code sparks!
        var kbY = torsoY + torsoH * 0.72
        ctx.fillStyle = "rgba(56, 189, 248, 0.22)"
        ctx.strokeStyle = "rgba(56, 189, 248, 0.82)"
        ctx.lineWidth = 1.5
        ctx.beginPath()
        ctx.roundedRect(-unit * 0.64, kbY, unit * 1.28, unit * 0.22, 4, 4)
        ctx.fill()
        ctx.stroke()

        var lHandDy = Math.sin(t * 7.5) * (unit * 0.09)
        var rHandDy = -Math.sin(t * 7.5) * (unit * 0.09)
        ctx.fillStyle = "#f8fafc"
        ctx.strokeStyle = "#1e293b"
        ctx.lineWidth = 1.5
        ctx.beginPath()
        ctx.arc(-unit * 0.34, kbY + lHandDy, unit * 0.13, 0, Math.PI * 2)
        ctx.arc(unit * 0.34, kbY + rHandDy, unit * 0.13, 0, Math.PI * 2)
        ctx.fill()
        ctx.stroke()

        // Floating neon code particles rising from holo-keyboard
        for (var sp = 0; sp < 3; sp++) {
          var prog = ((t * 0.9 + sp * 0.33) % 1.0)
          var sx = (sp - 1) * unit * 0.34
          var sy = kbY - prog * unit * 0.55
          ctx.fillStyle = sp === 1 ? pal.trim : "#38bdf8"
          ctx.globalAlpha = 1.0 - prog
          ctx.fillRect(sx - 4, sy, 8, 2.5)
          ctx.globalAlpha = 1.0
        }
      } else if (status === "needs_you") {
        // Waving right arm calling your attention!
        var waveAng = -0.55 + Math.sin(t * 4.5) * 0.32
        ctx.save()
        ctx.translate(torsoW * 0.50, torsoY + unit * 0.16)
        ctx.rotate(waveAng)
        ctx.fillStyle = pal.armorTop
        ctx.strokeStyle = "#1e293b"
        ctx.lineWidth = 1.6
        ctx.beginPath()
        ctx.roundedRect(-unit * 0.10, -unit * 0.52, unit * 0.20, unit * 0.52, unit * 0.10, unit * 0.10)
        ctx.fill()
        ctx.stroke()
        ctx.restore()

        // Resting left hand
        ctx.fillStyle = pal.armorTop
        ctx.beginPath()
        ctx.arc(-torsoW * 0.52, torsoY + torsoH * 0.68, unit * 0.13, 0, Math.PI * 2)
        ctx.fill()
      } else {
        // Calm poised hands resting on console rim
        ctx.fillStyle = pal.armorTop
        ctx.strokeStyle = "#1e293b"
        ctx.lineWidth = 1.5
        ctx.beginPath()
        ctx.arc(-torsoW * 0.44, torsoY + torsoH * 0.78, unit * 0.13, 0, Math.PI * 2)
        ctx.arc(torsoW * 0.44, torsoY + torsoH * 0.78, unit * 0.13, 0, Math.PI * 2)
        ctx.fill()
        ctx.stroke()
      }

      ctx.restore()
    }

    onPaint: {
      var ctx = getContext("2d")
      var w = width
      var h = height
      if (w <= 2 || h <= 2) return
      ctx.reset()

      var crew = root.visibleCrew
      var count = crew.length

      // ---------------------------------------------------------
      // COMPACT MEDALLION MODE (84x84 circular pin on Desktop)
      // ---------------------------------------------------------
      if (root.compact) {
        if (count > 0) {
          drawMechaBot(ctx, w * 0.50, h * 0.62, w * 0.28, crew[0], 0, false)
        } else {
          // Standby glowing Cosmos emblem when 0 agents are running
          ctx.strokeStyle = "rgba(255, 255, 255, 0.55)"
          ctx.lineWidth = 2.0
          ctx.beginPath()
          ctx.arc(w * 0.5, h * 0.52, w * 0.22, 0, Math.PI * 2)
          ctx.stroke()
        }
        return
      }

      // ---------------------------------------------------------
      // FULL INDUSTRIAL CYBER-LOFT ARCHITECTURE + EXACT N ROBOTS
      // ---------------------------------------------------------
      // 1. Factory-Loft Steel Window Mullions & Arched Top Ribbing
      ctx.strokeStyle = "rgba(18, 22, 34, 0.86)"
      ctx.lineWidth = 4.5
      ctx.beginPath()
      ctx.moveTo(w * 0.34, 0)
      ctx.lineTo(w * 0.34, h * 0.66)
      ctx.moveTo(w * 0.66, 0)
      ctx.lineTo(w * 0.66, h * 0.66)
      ctx.moveTo(w * 0.05, h * 0.29)
      ctx.lineTo(w * 0.95, h * 0.29)
      ctx.stroke()

      // Warm exposed-brick / dark-timber side piers framing the loft
      ctx.fillStyle = "#18151c"
      ctx.fillRect(0, 0, w * 0.055, h)
      ctx.fillRect(w * 0.945, 0, w * 0.055, h)

      // 2. Two Staggered Warm Edison Pendant Lamps + Golden Bloom
      var lamps = [
        { x: w * 0.19, y: h * 0.14, r: 14 },
        { x: w * 0.83, y: h * 0.11, r: 11 }
      ]
      for (var li = 0; li < lamps.length; li++) {
        var lp = lamps[li]
        var bloom = ctx.createRadialGradient(lp.x, lp.y + 4, 2, lp.x, lp.y + 12, lp.r * 5.2)
        bloom.addColorStop(0.0, "rgba(255, 210, 125, 0.52)")
        bloom.addColorStop(0.45, "rgba(249, 158, 58, 0.16)")
        bloom.addColorStop(1.0, "rgba(249, 158, 58, 0.0)")
        ctx.fillStyle = bloom
        ctx.beginPath()
        ctx.arc(lp.x, lp.y + 12, lp.r * 5.2, 0, Math.PI * 2)
        ctx.fill()

        ctx.strokeStyle = "#2b272a"
        ctx.lineWidth = 2
        ctx.beginPath()
        ctx.moveTo(lp.x, 0)
        ctx.lineTo(lp.x, lp.y - 6)
        ctx.stroke()

        ctx.fillStyle = "#ffe8a3"
        ctx.beginPath()
        ctx.arc(lp.x, lp.y + 2, lp.r * 0.46, 0, Math.PI * 2)
        ctx.fill()

        ctx.fillStyle = "#925c34"
        ctx.beginPath()
        ctx.arc(lp.x, lp.y, lp.r, Math.PI, Math.PI * 2)
        ctx.closePath()
        ctx.fill()
      }

      // 3. Elevated Holographic Mezzanine Catwalk (visible when 3+ agents are active!)
      if (count >= 3) {
        var mezY = h * 0.435
        var mezGrad = ctx.createLinearGradient(w * 0.14, mezY, w * 0.86, mezY)
        mezGrad.addColorStop(0.0, "rgba(22, 28, 45, 0.0)")
        mezGrad.addColorStop(0.18, "rgba(24, 32, 52, 0.92)")
        mezGrad.addColorStop(0.82, "rgba(24, 32, 52, 0.92)")
        mezGrad.addColorStop(1.0, "rgba(22, 28, 45, 0.0)")
        ctx.fillStyle = mezGrad
        ctx.fillRect(w * 0.12, mezY, w * 0.76, 10)

        // Glowing cyan/amber mezzanine safety rail
        ctx.strokeStyle = "rgba(56, 189, 248, 0.48)"
        ctx.lineWidth = 1.6
        ctx.beginPath()
        ctx.moveTo(w * 0.18, mezY)
        ctx.lineTo(w * 0.82, mezY)
        ctx.stroke()

        // Draw upper mezzanine robots first (proper painter's depth order!)
        for (var m = 0; m < count; m++) {
          var mSeat = root.seatPosition(m, count)
          if (mSeat.tier === "mezzanine") {
            drawMechaBot(ctx, w * mSeat.x, h * mSeat.y, w * 0.088 * mSeat.scale, crew[m], m, root.hoveredSeat === m)
          }
        }
      }

      // 4. Left Wall AI Compute Server Rack + Right Lush Monstera Plant
      var rackX = w * 0.06
      var rackY = h * 0.45
      var rackW = w * 0.11
      var rackH = h * 0.21
      ctx.fillStyle = "#111624"
      ctx.strokeStyle = "rgba(148, 163, 184, 0.25)"
      ctx.lineWidth = 1.2
      ctx.beginPath()
      ctx.roundedRect(rackX, rackY, rackW, rackH, 4, 4)
      ctx.fill()
      ctx.stroke()

      for (var bl = 0; bl < 5; bl++) {
        var by = rackY + 7 + bl * ((rackH - 12) / 5)
        ctx.fillStyle = "#1e293b"
        ctx.fillRect(rackX + 4, by, rackW - 8, 5)
        var blinkOn = ((Math.floor(root.phase * 3 + bl * 1.7) % 3) !== 0)
        ctx.fillStyle = bl % 2 === 0 ? (blinkOn ? "#38bdf8" : "#1e3a5f") : (blinkOn ? "#4ade80" : "#14532d")
        ctx.fillRect(rackX + 6, by + 1, 4, 3)
        ctx.fillStyle = "#f59e0b"
        ctx.fillRect(rackX + 13, by + 1, 3, 3)
      }

      // Lush Monstera plant on right ledge
      var plX = w * 0.91
      var plY = h * 0.59
      ctx.fillStyle = "#15803d"
      for (var lf = -2; lf <= 2; lf++) {
        ctx.save()
        ctx.translate(plX, plY)
        ctx.rotate(lf * 0.32 - 0.18)
        ctx.scale(0.38, 1.0)
        ctx.beginPath()
        ctx.arc(0, -16, 16, 0, Math.PI * 2)
        ctx.fill()
        ctx.restore()
      }
      ctx.fillStyle = "#7c4a32"
      ctx.beginPath()
      ctx.roundedRect(plX - 10, plY - 2, 20, 16, 3, 3)
      ctx.fill()

      // 5. Foreground Curved Walnut & Neon-Trimmed Battle-Station Desk
      var deskY = h * 0.625
      var deskGrad = ctx.createLinearGradient(0, deskY, 0, h)
      deskGrad.addColorStop(0.0, "#433026")
      deskGrad.addColorStop(0.16, "#271d1a")
      deskGrad.addColorStop(1.0, "#121318")
      ctx.fillStyle = deskGrad
      ctx.beginPath()
      ctx.moveTo(0, deskY + 10)
      ctx.quadraticCurveTo(w * 0.5, deskY - 12, w, deskY + 10)
      ctx.lineTo(w, h)
      ctx.lineTo(0, h)
      ctx.closePath()
      ctx.fill()

      // Warm golden + accent neon edge strip along desk curve
      ctx.strokeStyle = "rgba(251, 191, 106, 0.52)"
      ctx.lineWidth = 2.0
      ctx.beginPath()
      ctx.moveTo(w * 0.04, deskY + 8)
      ctx.quadraticCurveTo(w * 0.5, deskY - 11, w * 0.96, deskY + 8)
      ctx.stroke()

      // Foreground desk robots (exact 1-to-1 with detected agents!)
      for (var d = 0; d < count; d++) {
        var dSeat = root.seatPosition(d, count)
        if (dSeat.tier !== "mezzanine") {
          drawMechaBot(ctx, w * dSeat.x, h * dSeat.y, w * 0.092 * dSeat.scale, crew[d], d, root.hoveredSeat === d)
        }
      }

      // Steaming espresso mug on foreground right desk corner
      var mugX = w * 0.90
      var mugY = deskY - 6
      ctx.fillStyle = "#f5ebe0"
      ctx.beginPath()
      ctx.roundedRect(mugX - 7, mugY, 14, 13, 3, 3)
      ctx.fill()
      ctx.strokeStyle = "rgba(255, 245, 235, 0.34)"
      ctx.lineWidth = 1.3
      ctx.beginPath()
      ctx.moveTo(mugX, mugY - 2)
      ctx.quadraticCurveTo(mugX + Math.sin(root.phase) * 3, mugY - 9, mugX - 1, mugY - 15)
      ctx.stroke()

      // Standby Hologram when 0 agents are detected (0 robots!)
      if (count === 0) {
        ctx.fillStyle = "rgba(15, 23, 42, 0.72)"
        ctx.strokeStyle = "rgba(56, 189, 248, 0.45)"
        ctx.lineWidth = 1.4
        ctx.beginPath()
        ctx.roundedRect(w * 0.24, h * 0.44, w * 0.52, 30, 10, 10)
        ctx.fill()
        ctx.stroke()
      }
    }
  }

  // Standby label when 0 agents are open
  Text {
    visible: !root.compact && root.visibleCrew.length === 0
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(parent.height * 0.44) + 8
    textFormat: Text.PlainText
    text: "STANDBY · 0 ACTIVE ROBOTS"
    font.family: Style.font.family
    font.pixelSize: Style.space(10)
    font.bold: true
    font.letterSpacing: 0.9
    color: "#93c5fd"
  }

  // 3. Interactive Nameplates + Status Badges for EACH Detected Robot (1-to-1!)
  Repeater {
    model: root.compact ? [] : root.visibleCrew
    delegate: Item {
      required property var modelData
      required property int index

      readonly property var seat: root.seatPosition(index, root.visibleCrew.length)
      readonly property string st: String(modelData.status || "finished")
      readonly property color badgeColor: st === "needs_you" ? "#fbbf24" : (st === "working" ? "#38bdf8" : "#4ade80")

      x: Math.round(root.width * seat.x - width / 2)
      y: Math.round(root.height * seat.y - height / 2)
      width: Math.round(root.width * 0.22 * seat.scale)
      height: Math.round(root.width * 0.24 * seat.scale)

      // Floating status bubble top-right of robot helmet
      Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -Style.space(2)
        anchors.topMargin: -Style.space(4)
        width: Style.space(22)
        height: Style.space(22)
        radius: width / 2
        color: "#0f131d"
        border.width: 1.6
        border.color: parent.badgeColor

        Rectangle {
          anchors.centerIn: parent
          width: Style.space(15)
          height: Style.space(15)
          radius: width / 2
          color: parent.parent.badgeColor

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: st === "needs_you" ? "?" : (st === "working" ? "⚡" : "✓")
            font.family: Style.font.family
            font.pixelSize: Style.space(9)
            font.bold: true
            color: "#0b0f17"
          }
        }
      }

      // Crisp mini glass nameplate beneath robot ("Antigravity", "Claude", "ChatGPT"...)
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -Style.space(8)
        height: Style.space(17)
        width: tagRow.implicitWidth + Style.space(10)
        radius: height / 2
        color: botMouse.containsMouse ? Qt.rgba(0.12, 0.16, 0.26, 0.96) : Qt.rgba(0.06, 0.08, 0.14, 0.86)
        border.width: 1
        border.color: botMouse.containsMouse ? parent.badgeColor : Qt.rgba(1, 1, 1, 0.22)

        Row {
          id: tagRow
          anchors.centerIn: parent
          spacing: Style.space(4)

          Rectangle {
            width: Style.space(5)
            height: Style.space(5)
            radius: width / 2
            color: badgeColor
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            textFormat: Text.PlainText
            text: String(modelData.agentName || "Agent")
            font.family: Style.font.family
            font.pixelSize: Style.space(9)
            font.bold: true
            color: "#f8fafc"
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      MouseArea {
        id: botMouse
        anchors.fill: parent
        anchors.margins: -Style.space(4)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hoveredSeat = index
        onExited: if (root.hoveredSeat === index) root.hoveredSeat = -1
        onClicked: {
          if (modelData.windowAddress) {
            root.agentClicked(String(modelData.windowAddress))
          }
        }
      }
    }
  }
}
