// The Orb pack. Eight thinking indicators, and this is the one family in Murmur
// that is allowed to draw a countable thing.
//
//   mo_breathe   the resting orb: the whole lattice inhaling and exhaling, the
//                breath arriving at the front of the sphere before the back.
//   mo_orbit     latitude bands streaming around the sphere at neighbouring
//                speeds, the way a gas planet's do.
//   mo_glimmer   dots catching light one after another in a scattered order: a
//                constellation being counted.
//   mo_vortex    the lattice drawn up toward a pole and twisted as it goes,
//                wound into a crown and released.
//   mo_gather    dispersion converging into one bright ring. The only species
//                here with an arrival, so the only one that reads `epoch`.
//   mo_stir      dots jostled out of their seats and settling back: the sphere
//                thinking with its hands.
//   mo_daybreak  a terminator sweeping the sphere. Dawn crossing a small planet.
//   mo_skein     dots strung along a winding thread that wraps the ball, with a
//                bead of light running its length.
//
// WHY THIS FAMILY EXISTS AT ALL. Everywhere else in Murmur the dot is banned,
// and the ban is not decoration: a discrete circle is the fastest way to make a
// generative field look like a screensaver. The carve-out here is deliberate and
// narrow. The rotating fibonacci dot sphere is THE canonical AI thinking
// indicator -- the thing a person recognises before they have read a word of the
// UI -- and a set of thinking indicators that refuses to speak the genre at all
// is a set with a hole in it. So the genre is spoken, and it is spoken in the
// house's own material rather than in the reference grid's flat white.
//
// WHAT "IN OUR STYLE" HAD TO MEAN, concretely, or this would have been a clone:
//
//   THE DOTS WEAR THE RAIL. Not one pixel in this file is white. A front dot is
//   an amber BODY with a CREAM PEAK at its centre where the light sits; a dot on
//   the shaded flank of the sphere is amber all through; a dot on the back
//   hemisphere sinks toward the rail's warm shadow stop and never toward grey.
//   That is the value hierarchy the device review asked for, and here it has a
//   second job: it is also the thing that makes a flat scatter of circles read
//   as a SPHERE.
//
//   THE ACCENTS ARE COLOUR, NOT BRIGHTNESS. A fraction of the dots -- chosen by
//   a hash of the LATTICE INDEX, so a dot keeps its accent while it is jostled,
//   swept, wound and re-seated -- refuse to go cream. They walk the same energy
//   onto a band that tops out at the tone's saturated stop, so where their
//   neighbours go pale they stay gold. In a one-hue palette that is the only
//   honest way to have an accent at all, and it is why the accent set does not
//   flicker: it is a property of the dot, never of the pixel.
//
//   THE GROUND IS INK AND THE SILHOUETTE IS THE FIGURE. The sphere brings itself
//   to nothing at its own limb, well inside the circle clip, so the clip is a
//   guarantee and not the design. Under the dots there is a very faint warm body
//   -- about a twentieth of the energy of a lit dot -- because a sphere with
//   nothing between its dots is a handful of confetti, and the figure law wants
//   an object.
//
// THE HARD PART, AND HOW IT IS DONE. A dot sphere in a fragment shader is a
// nearest-point query: for this pixel, which lattice point is under it, and how
// far. Looping over a hundred and fifty points per pixel is the obvious answer
// and it is the wrong one -- at 300 pt that is a hundred and twenty million
// distance tests a frame. So the lookup here is the INVERSE SPHERICAL FIBONACCI
// mapping (Keinert, Innmann, Sanger, Stamminger, SIGGRAPH Asia 2015): the
// spiral's own arithmetic is inverted in closed form to name the lattice cell a
// direction falls in, and the answer is the four corners of that cell. Four
// candidates, constant time, independent of the lattice count. mo_lattice below
// is that, derived rather than transcribed so the reasoning stays on the page.
//
// It is called twice per pixel -- once for the near hit of the view ray and once
// for the far one -- because the back hemisphere showing dimly THROUGH the front
// is most of what makes the ball look round, and there is no cheaper way to know
// what is back there than to ask.
//
// THE TEMPO. Every species turns. A dot sphere that is not rotating is a
// diagram, so the slow spin is the family's heartbeat and each species' own
// mechanic rides on top of it rather than replacing it. About sixteen seconds a
// turn at speed 1, with an fBm wander on the rate so it is never a metronome,
// and one aperiodic gesture per species on the four-to-nine second clock the
// signal pack uses. Motion the eye feels rather than watches.
//
// COPIED HELPERS. Cross-file Metal linkage is not guaranteed, so the kit is
// copied out of FieldLab.metal and FieldPackPour.metal VERBATIM under an mo_
// prefix, the way the house has done it before. Copied, unchanged except for the
// name:
//
//   mo_hash, mo_grad3, mo_noise3, mo_hash1, mo_vnoise1, mo_fbm1,
//   mo_srgb_to_linear, mo_linear_to_srgb, mo_linear_to_oklab,
//   mo_oklab_to_linear, mo_lch, MOPalette, mo_palette, mo_shade,
//   mo_out, mo_knee, mo_settle_law (pv_exhale_law), mo_tier, mo_flourish
//
// Their comments come with them: the reasoning is the part worth carrying. Not
// copied: fl_noised3 / fl_fbmd3, because nothing here lights a surface by its
// slope -- the light on a dot comes from where the dot IS on the ball, which is
// a dot product and free. fl_edge is not copied either; mo_containment is the
// radial equivalent, written rather than adapted. And fl_fbmd3's plain sibling
// fl_fbm3 is not copied because the two species that warp their lattice want a
// single BROAD fold rather than a spectrum -- an octave stack folds the sphere
// at several scales at once, which disperses a lattice into fog instead of into
// a scatter -- so they call mo_noise3 three times for a vector and stop there.
// Copying an fBm nobody calls would only leave dead code behind a prefix.
//
// ONE RENDERER, EIGHT SPECIES, and this pack is the only one built that way. The
// other four families each invent a figure per species, so a shared body would
// have been a straitjacket. Here the SPEC says it outright: "the figure is
// always the sphere of dots". Eight private copies of the same ray cast, the
// same lattice lookup and the same shading law would not have made eight species
// -- it would have made eight chances to drift apart. So the ball is written
// once, in mo_orb, and each species is exactly the two things that are actually
// its own: mo_warp, which says where its dots sit, and mo_level, which says how
// brightly each one burns. Both are switched on a tag that is uniform across the
// whole draw, so the branch costs nothing and every species still gets its own
// physics and its own paragraph.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - The copied kit
//
// Everything in this section is FieldLab.metal's or FieldPackPour.metal's,
// verbatim, renamed.

/// An integer avalanche. Lattice coordinates in, well-mixed bits out. A sine
/// hash was the other option and it drifts into visible repeats once the domain
/// gets large, which the long previews here would find.
static inline uint mo_hash(uint3 v) {
    uint h = v.x * 1597334673u ^ v.y * 3812015801u ^ v.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u;
    h ^= h >> 13; h *= 3266489917u;
    h ^= h >> 16;
    return h;
}

/// A unit vector distributed uniformly on the sphere, from one lattice cell.
/// Uniform matters: gradients bunched near the poles put a grain in the field
/// that reads as a weave once the octaves stack.
static inline float3 mo_grad3(int3 c) {
    uint h = mo_hash(uint3(c + 4096));
    float z = fma(float(h & 0xFFFFu), 2.0 / 65535.0, -1.0);
    float a = float((h >> 16) & 0xFFFFu) * (6.28318530718 / 65536.0);
    float r = sqrt(max(0.0, 1.0 - z * z));
    return float3(r * cos(a), r * sin(a), z);
}

/// The value alone, for the places that never ask what the slope is: the warp
/// offsets and the sheets behind the first. Roughly a third cheaper.
static float mo_noise3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    int3 c = int3(i);

    float va = dot(mo_grad3(c + int3(0, 0, 0)), f - float3(0.0, 0.0, 0.0));
    float vb = dot(mo_grad3(c + int3(1, 0, 0)), f - float3(1.0, 0.0, 0.0));
    float vc = dot(mo_grad3(c + int3(0, 1, 0)), f - float3(0.0, 1.0, 0.0));
    float vd = dot(mo_grad3(c + int3(1, 1, 0)), f - float3(1.0, 1.0, 0.0));
    float ve = dot(mo_grad3(c + int3(0, 0, 1)), f - float3(0.0, 0.0, 1.0));
    float vf = dot(mo_grad3(c + int3(1, 0, 1)), f - float3(1.0, 0.0, 1.0));
    float vg = dot(mo_grad3(c + int3(0, 1, 1)), f - float3(0.0, 1.0, 1.0));
    float vh = dot(mo_grad3(c + int3(1, 1, 1)), f - float3(1.0, 1.0, 1.0));

    return mix(mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y),
               mix(mix(ve, vf, u.x), mix(vg, vh, u.x), u.y), u.z);
}

static inline float mo_hash1(float cell, float lane) {
    return float(mo_hash(uint3(uint(int(cell) + 32768), uint(int(lane) + 32768), 0x9E3779B9u)) >> 8)
         * (1.0 / 16777216.0);
}

/// Value noise on a line, quintic-interpolated so its slope is continuous and
/// a silhouette built on it has no corners the eye can find.
static inline float mo_vnoise1(float x, float lane) {
    float i = floor(x), f = x - i;
    float u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(mo_hash1(i, lane), mo_hash1(i + 1.0, lane), u) * 2.0 - 1.0;
}

/// fBm on a line. Amplitude halves, frequency a hair past doubles (2.03, so no
/// two octaves ever land on the same cell wall). Range is about plus or minus
/// one for four octaves.
static float mo_fbm1(float x, int octaves, float lane) {
    float v = 0.0, amp = 0.5, f = 1.0;
    for (int i = 0; i < octaves; i++) {
        v += amp * mo_vnoise1(x * f, lane + float(i) * 37.0);
        amp *= 0.5;
        f *= 2.03;
    }
    return v;
}

static inline float3 mo_srgb_to_linear(float3 c) {
    c = max(c, 0.0);
    return select(c * (1.0 / 12.92), pow((c + 0.055) * (1.0 / 1.055), 2.4), c > 0.04045);
}

static inline float3 mo_linear_to_srgb(float3 c) {
    c = max(c, 0.0);
    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c > 0.0031308);
}

static inline float3 mo_linear_to_oklab(float3 c) {
    float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
    float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
    float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;
    float l_ = pow(max(l, 0.0), 1.0 / 3.0);
    float m_ = pow(max(m, 0.0), 1.0 / 3.0);
    float s_ = pow(max(s, 0.0), 1.0 / 3.0);
    return float3(0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
                  1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
                  0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_);
}

static inline float3 mo_oklab_to_linear(float3 lab) {
    float l_ = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
    float m_ = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
    float s_ = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
    float l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    return float3( 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                  -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                  -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

/// Lightness, chroma, hue back into OKLAB's rectangular form.
static inline float3 mo_lch(float L, float C, float h) {
    return float3(L, C * cos(h), C * sin(h));
}

/// Four OKLAB stops built from one anchor: the tone the indicator wears.
/// Ordered dark to bright, and never more than one hue family wide.
struct MOPalette { float3 s0, s1, s2, s3; };

/// s0 is the ink the whole app sits on, so a field at zero dissolves into the
/// screen with no seam. s1 is a deep shadow that KEEPS the tone's hue at half
/// its chroma, which is what stops the dark end going grey. s2 is the tone. s3
/// is a pale specular a few degrees warmer, because light that has passed
/// through anything comes out warmer than the thing it lit.
/// `depth` opens the range from both ends without letting the hue wander.
static MOPalette mo_palette(half4 inkColor, half4 toneColor, float hueShift, float depth) {
    float3 ink = mo_linear_to_oklab(mo_srgb_to_linear(float3(inkColor.rgb)));
    float3 tone = mo_linear_to_oklab(mo_srgb_to_linear(float3(toneColor.rgb)));

    float L = tone.x;
    float C = length(tone.yz);
    float h = atan2(tone.z, tone.y) + hueShift;
    float d = clamp(depth, 0.30, 2.00);

    // The shadow shifts WARM as it darkens, roughly twenty degrees of hue
    // toward ember, and keeps most of its chroma rather than draining to grey.
    // Both of those are the difference between a deep amber and mud: a straight
    // desaturating fall from gold to ink passes through olive, and olive is what
    // the first cut of every one of these fields looked like.
    MOPalette p;
    p.s0 = ink;
    p.s1 = mo_lch(mix(ink.x, L, 0.30 / d), C * (0.52 + 0.10 * d), h - 0.35);
    p.s2 = mo_lch(L, C, h);
    p.s3 = mo_lch(min(L * (1.20 + 0.12 * d), 0.93), C * 0.55, h + 0.10);
    return p;
}

/// Walk the family. Three segments, each eased so its ends are flat, which
/// makes the joins C1: no kink shows up as a contour line in a smooth field.
/// Returns LINEAR light; mo_out does the encoding.
static float3 mo_shade(MOPalette p, float t) {
    t = clamp(t, 0.0, 1.0);
    float3 lab;
    if (t < 0.40) {
        lab = mix(p.s0, p.s1, smoothstep(0.0, 1.0, t * 2.5));
    } else if (t < 0.78) {
        lab = mix(p.s1, p.s2, smoothstep(0.0, 1.0, (t - 0.40) * (1.0 / 0.38)));
    } else {
        lab = mix(p.s2, p.s3, smoothstep(0.0, 1.0, (t - 0.78) * (1.0 / 0.22)));
    }
    return mo_oklab_to_linear(lab);
}

/// The last thing every field does. One code value of triangular-PDF
/// interleaved-gradient dither, in the encoded space where the quantization
/// actually happens. Triangular rather than uniform because uniform dither
/// leaves a faint texture of its own in flat areas; triangular does not.
static inline half4 mo_out(float3 linearRGB, float2 pixel) {
    float3 c = mo_linear_to_srgb(linearRGB);
    float n = fract(52.9829189 * fract(dot(pixel, float2(0.06711056, 0.00583715))));
    float tri = n < 0.5 ? (sqrt(2.0 * n) - 1.0) : (1.0 - sqrt(max(0.0, 2.0 - 2.0 * n)));
    c += tri * (1.0 / 255.0);
    return half4(half3(saturate(c)), 1.0h);
}

/// A soft knee, the same one the route curtain uses. Below the knee nothing
/// changes; above it the tail compresses asymptotically instead of clipping,
/// which is what stops a bright field turning into flat white paper.
static inline float mo_knee(float x, float knee) {
    return x < knee ? x : knee + (1.0 - knee) * (1.0 - exp(-(x - knee) / max(1.0 - knee, 1e-3)));
}

/// THE SETTLE LAW, copied from FieldPackPour.metal's pv_exhale_law. Motion
/// stated as a SPEED, position drawn from that speed's closed-form INTEGRAL:
///
///   v(tau) = hold + (1 - hold) e^(-k tau),   k = 3 / settleTime
///   D(tau) = hold tau + (1 - hold) (1 - e^(-k tau)) / k
///
/// k is 3 / settleTime rather than 1 / settleTime so that the dial means what it
/// says: at tau = settleTime the speed is within five per cent of the hold,
/// which is the instant a person would call it stopped. D is the exact integral
/// of v, so the field's position at any t is the position the animation would
/// have reached -- no frame has to remember the last one, and a screenshot rig
/// or a scrubbed slider lands exactly where the animation would have been. The
/// floor is not zero: a field that stops dead is a frozen image; a field that
/// keeps a whisper of drift is a held breath. Returns (v, D, e), where e is the
/// still-moving fraction.
static inline float3 mo_settle_law(float tau, float settleTime) {
    const float HOLD = 0.055;
    float E = max(settleTime, 0.50);
    float k = 3.0 / E;
    float e = exp(-k * max(tau, 0.0));
    float v = HOLD + (1.0 - HOLD) * e;
    float D = HOLD * max(tau, 0.0) + (1.0 - HOLD) * (1.0 - e) / k;
    return float3(v, D, e);
}

/// THE VALUE HIERARCHY, as one curve, copied from the signal pack where it was
/// written. Three tiers or it fails: ink ground, amber body, CREAM PEAKS.
///
/// One number gets all three by spending the rail unevenly. The bottom
/// seventy-eight per cent of the energy is compressed into the rail's first
/// seventy-two, which is the whole amber body from shadow to tone, so most of
/// the picture is warm and readable and none of it is near white. The last
/// twenty-two per cent of the energy is spent on the rail's last twenty-eight,
/// where the specular lives, so only the figure's key structure goes cream --
/// and when it goes it goes decisively rather than creeping.
///
/// The join is smoothed over a fifth of the range, because a slope kink in a
/// map this shallow shows up as a contour line in a smooth field. It is the
/// same reason mo_shade eases its own segment joins.
static inline float mo_tier(float e) {
    float x = clamp(e, 0.0, 1.0);
    const float K = 0.78;
    float body = (x / K) * 0.72;
    float peak = 0.72 + ((x - K) / (1.0 - K)) * 0.28;
    return mix(body, peak, smoothstep(K - 0.10, K + 0.10, x));
}

/// THE FLOURISH CLOCK, and it is the pack's play mechanism. Copied from the
/// signal pack, which wrote it, because the three rules it keeps are the same
/// three rules here.
///
/// APERIODIC, NEVER A METRONOME. Time is cut into 6.5 second slots and each slot
/// holds exactly one gesture, but WHERE in its slot the gesture falls is hashed
/// per slot. The interval between two onsets is therefore the slot length plus
/// the difference of two independent jitters -- about four to nine seconds, with
/// no two gaps the same and nothing for the eye to lock onto. A gesture on a
/// timer stops being play and becomes a tick.
///
/// DETERMINISTIC. The slot index is floor(t / SLOT) and everything else is a
/// hash of it, so any t at all renders the correct frame: a screenshot rig, a
/// scrubbed slider and a resumed app all agree. There is no state between frames
/// anywhere in this pack and play does not get to be the exception.
///
/// NOTHING SNAPS. The envelope is sin^2(pi u), which is zero with zero slope at
/// both ends. It does not begin, it arrives; it does not stop, it finishes.
///
/// Returns (envelope, progress, a per-gesture random, the slot index). The
/// random is what lets each occurrence differ -- which band surges, which way
/// the chain runs, where the thread is pulled -- so the play is never the same
/// twice either.
static float4 mo_flourish(float t, float lane) {
    const float SLOT = 6.5;
    float slot = floor(t / SLOT);
    float local = t - slot * SLOT;
    float start = 1.15 + 2.20 * mo_hash1(slot, lane);
    float dur   = 1.60 + 1.40 * mo_hash1(slot + 811.0, lane);
    float u = (local - start) / dur;
    float sn = sin(3.14159265 * clamp(u, 0.0, 1.0));
    float env = (u <= 0.0 || u >= 1.0) ? 0.0 : sn * sn;
    return float4(env, clamp(u, 0.0, 1.0), mo_hash1(slot + 1607.0, lane), slot);
}

// MARK: - The pack's own tools

constant float MO_PHI  = 1.6180339887498949;   // the golden ratio
constant float MO_INVP = 0.6180339887498949;   // 1 / PHI, which is also PHI - 1
constant float MO_TAU  = 6.2831853071795865;

/// The sphere's radius, in uv. The view clips at 0.5; 0.368 leaves the orb a
/// comfortable margin all round, and the species that swell (breathe's inhale,
/// gather's dispersion) have room to reach about 0.40 without ever approaching
/// the rim. At 300 pt that is a 221 pt ball inside a 300 pt circle, which is the
/// proportion the reference indicator uses and the one that reads as an OBJECT
/// rather than as a texture filling a disc.
constant float MO_R = 0.368;

/// THE KEY LIGHT, in view space, and note that +y is DOWN in this frame: this is
/// a light from the upper left, tipped toward the viewer. Fixed for the whole
/// pack, because a family whose light moves between species is a family with no
/// light at all. mo_daybreak is the exception and says so in its own paragraph.
///
/// IT MUST BE EXACTLY UNIT, and the reason is worth the line it takes. The whole
/// pack shades a dot with lam = 0.5 + 0.5 dot(p, MO_KEY) and then raises lam to
/// a fractional power. That is only in range if |MO_KEY| is one: at 1.0247 --
/// which is what this constant was before, three digits typed by hand and never
/// measured -- the dot product reaches -1.0247 somewhere on the far hemisphere,
/// lam goes very slightly negative, and pow() of a negative base under the
/// project's fast-math build is a NaN. The NaN then eats the whole pixel:
/// saturate(NaN) is zero, so the ink, the body and every dot at that pixel come
/// out black. It printed as a circular hole about a sixth of the ball across at
/// the lower right, on every species, at every size, at every rotation -- fixed
/// on screen rather than on the sphere, because the light lives in view space.
/// Three per cent of the ball, gone, from a vector that was 2.5% too long.
constant float3 MO_KEY = float3(-0.3983662, -0.5179150, 0.7570128);

/// The axis the success wavefront travels along, in view space. Upper left to
/// lower right and a little toward the viewer, so the front crosses the face of
/// the ball rather than sweeping its silhouette. Unit for the same reason, and
/// so that the wave's travel from +1.30 to -1.30 covers the ball exactly.
constant float3 MO_SWEEP = float3(-0.6550295, -0.6973379, 0.2909575);

/// A normalize that cannot hand back a NaN. Two species add a fold to the query
/// direction before renormalising it, and gather's fold at birth is large enough
/// that it can in principle cancel the direction it is added to; normalize() of
/// the zero vector is a NaN, and a NaN in a direction is a black pixel by the
/// same route the light was. Measure-zero events are still events when a shader
/// runs a million pixels a frame for hours.
static inline float3 mo_unit(float3 v) {
    float l = length(v);
    return (l > 1.0e-4) ? v / l : float3(0.0, 0.0, 1.0);
}

/// THE CONTAINMENT. fl_edge's job, done for a circle instead of a screen.
///
/// It does almost nothing here and that is the point. The other packs need this
/// to stop an organic field being sliced by the clip; the orb brings itself to
/// pure ink at its own limb, at a uv radius of about 0.37, because there are no
/// lattice points outside the sphere and nothing to draw there. So the fall is
/// placed from 0.42 to 0.50 -- entirely in the empty ring between the ball and
/// the clip -- where it can catch a species that swells further than it meant to
/// and can never touch the figure. A guarantee, not the design.
static inline float mo_containment(float2 uv, float reach) {
    float r = length(uv) * 2.0;
    return 1.0 - smoothstep(reach, reach + 0.16, r);
}

/// The house finish, shared: ink underneath, the field composited into it by the
/// containment, the same knee the route curtain puts on its surface colour, and
/// the dither last. Every species ends on this line.
static inline half4 mo_finish(float3 field, float3 inkLin, float containment,
                              float2 position, float pixelScale) {
    float3 rgb = mix(inkLin, field, containment);
    rgb = float3(mo_knee(rgb.r, 0.90), mo_knee(rgb.g, 0.90), mo_knee(rgb.b, 0.90));
    return mo_out(rgb, position * pixelScale);
}

// MARK: - The state read

/// The EXTRA TURN responding adds, stated as the integral of its own ramp.
///
/// This is the same discipline as the settle law and it exists for the same
/// reason. `drive` ramps from 0 to 1 over T seconds; multiplying a rotation RATE
/// by (1 + k drive) and then by t would jump the sphere's angle by k times the
/// app's whole uptime the instant the state changed -- at any real t that is a
/// spin snapping to a random new orientation. So the drive's contribution to the
/// ANGLE is integrated in closed form instead, which means entering RESPONDING
/// accelerates the rotation from exactly where it was standing. Every species
/// adds this to its spin, and the three that also drive a second motion (orbit's
/// belts, glimmer's count, daybreak's sun, skein's thread) add it there too.
///
/// smoothstep's integral: T(u^3 - u^4/2) below T, and tau - T/2 above it. The
/// two agree at tau = T, so the angle is C1 and the acceleration has no corner.
static inline float mo_drive_turn(float tau, float T) {
    float u = clamp(max(tau, 0.0) / max(T, 1.0e-3), 0.0, 1.0);
    float below = T * (u * u * u - 0.5 * u * u * u * u);
    return (tau >= T) ? (max(tau, 0.0) - 0.5 * T) : below;
}

/// THE STATE READ, shared by all eight species.
///
/// Two of the five states get an in-shader design; the rest are carried by the
/// per-state parameter sets the Swift layer interpolates, which is the right
/// division of labour -- a dial change is a dial change and does not belong in
/// a branch here.
///
/// SUCCESS is THE LATTICE COMPLETES, and it is three things at once because a
/// dot sphere gives you three handles the other families do not have:
///
///   `crest` and `wave`   A WAVEFRONT of light travels the ball. `wave` is the
///                        front's position along MO_SWEEP, running from past one
///                        side to past the other over the first two thirds of
///                        the window, and every dot brightens as it passes. This
///                        is the part a person actually sees: light moving
///                        ACROSS an object, which is only legible because the
///                        object has countable parts.
///   `accord`             every dot briefly in agreement. Each species' own
///                        deviation -- the jostle, the scatter, the twist, the
///                        band shading, the thread's narrowness -- is scaled
///                        toward nothing while this holds, so for one breath the
///                        sphere is its own perfect lattice, evenly lit. That is
///                        the arrival. Then it lets go.
///   `settled`            what is left afterwards, held for as long as the state
///                        does: the ball a little brighter than it was, the way
///                        a thing that has just succeeded looks.
///
/// The light is NOT an overlay. Every species multiplies its own per-dot level,
/// so the surge travels through the dots because it IS the dots, scaled. A white
/// wash over the top would have been two lines of code and a different product.
///
/// One deliberate omission: `accord` never touches a rotation RATE. A rate is
/// multiplied by t, so changing it moves the sphere's angle by rate-delta times
/// however many seconds the app has been running, which at any real t is a
/// violent snap. Everything accord suppresses is an amplitude or an envelope,
/// which can go to zero and come back without moving anything discontinuously.
/// Where a species' deviation IS a rate -- orbit's differential bands -- accord
/// takes its brightness difference instead, which says the same thing.
///
/// RESPONDING is decisive drive: the sphere stops turning idly and DRIVES, and
/// each species leans its own mechanic the same way. `drive` ramps in over half
/// a second so entering the state is a lean and not a jolt.
struct MOState {
    float crest;    // success: the wavefront's amplitude
    float wave;     // success: the wavefront's position along MO_SWEEP
    float accord;   // success: how far the lattice is pulled into agreement
    float settled;  // success: the brightness left behind
    float drive;    // responding: directional urgency, held
    float turn;     // responding: the EXTRA ANGLE that urgency has turned so far
};

static MOState mo_state(float stateIndex, float stateTau) {
    MOState o;
    o.crest = 0.0; o.wave = 9.0; o.accord = 0.0; o.settled = 0.0;
    o.drive = 0.0; o.turn = 0.0;
    float tau = max(stateTau, 0.0);
    if (stateIndex > 2.5 && stateIndex < 3.5) {
        float a = clamp(tau / 1.20, 0.0, 1.0);
        // In over about 0.2 s, out over the rest. The first cut rose in seven
        // frames at 30 fps, which reads as a strobe rather than as an arrival.
        // An arrival wants to be seen arriving.
        o.crest  = smoothstep(0.0, 0.17, a) * (1.0 - smoothstep(0.46, 0.86, a));
        // Past the ball on both sides: at a = 0 the front has not reached the
        // near limb, at a = 0.66 it has left the far one, so no dot is left out.
        o.wave   = 1.30 - 2.60 * smoothstep(0.0, 0.66, a);
        o.accord = smoothstep(0.06, 0.42, a) * (1.0 - smoothstep(0.66, 1.0, a));
        o.settled = smoothstep(0.30, 1.05, a);
    } else if (stateIndex > 1.5 && stateIndex < 2.5) {
        o.drive = smoothstep(0.0, 0.55, tau);
        o.turn  = mo_drive_turn(tau, 0.55);
    }
    return o;
}

// MARK: - The lattice, and the inverse mapping that makes it affordable

/// The count. The reference orb scales its lattice with the view and it has to:
/// a 20 pt indicator drawn with a hundred and fifty dots is a grey pea, and a
/// 300 pt one drawn with forty is a bead necklace. So the count runs from about
/// forty-four at the small end to about a hundred and fifty-eight at the large,
/// which is the SPEC's default band, and the crossover sits at 150 pt because
/// that is roughly where a dot stops needing to be four pixels wide to survive.
///
/// `formScale` divides it by the square, because form scale means "bigger
/// forms": a doubled dot covers four times the sphere, so a quarter as many fit.
/// That is the honest coupling and it keeps the ball's coverage roughly constant
/// across the dial instead of turning it into a dial for density.
static inline float mo_count(float2 size, float formScale) {
    float pt = clamp(min(size.x, size.y), 12.0, 400.0);
    float n = mix(44.0, 158.0, smoothstep(18.0, 150.0, pt));
    float S = max(formScale, 0.10);
    return clamp(n / (S * S), 24.0, 320.0);
}

/// A fractional multiply that keeps its precision. Copied in spirit from the
/// paper's madfrac: the point is to get the fractional part of a product whose
/// integer part is large and uninteresting.
static inline float mo_madfrac(float a, float b) {
    float x = a * b;
    return x - floor(x);
}

/// The four candidates the inverse mapping hands back.
struct MOLattice {
    float3 q[4];
    float  i[4];
};

/// THE INVERSE SPHERICAL FIBONACCI MAPPING, and it is the whole reason this
/// pack is affordable. Keinert, Innmann, Sanger and Stamminger, SIGGRAPH Asia
/// 2015; derived here rather than transcribed, so the reasoning is on the page.
///
/// THE FORWARD LATTICE. Point i of n, the same spiral the reference orb builds
/// on the CPU:
///
///     cos(theta_i) = 1 - (2i + 1) / n          latitudes evenly spaced in z,
///                                              which is what makes the set
///                                              area-uniform on the sphere
///     phi_i        = 2 pi frac(i / PHI)        the golden angle, which is the
///                                              least rational turn there is and
///                                              therefore the one that never
///                                              lines the points up into rows
///
/// THE INVERSION. Ask what happens to a point when you step the index by delta.
/// The latitude moves EXACTLY linearly: d(cos theta) = -2 delta / n. The
/// longitude moves by 2 pi frac(delta / PHI), which is nonlinear in general --
/// but if delta is a FIBONACCI NUMBER F, then F / PHI is within about 1/F of a
/// whole number, so frac(F / PHI) is tiny and the longitude barely moves. That
/// is the trick and it is the only trick: two consecutive Fibonacci numbers give
/// two index steps whose (longitude, latitude) displacements are small, linearly
/// independent, and therefore a BASIS for the lattice near that latitude.
///
/// So: pick the Fibonacci level k that matches the ring spacing at this latitude
/// (that is the log; the spacing goes as 1/sqrt of the ring circumference, hence
/// the sin^2 term). Build the 2x2 basis from F_k and F_{k+1}. Invert it -- two
/// by two, so the inverse is four multiplies and a determinant. Floor the result
/// to name the cell. The cell's four corners are the four candidate indices, and
/// one of them is the nearest lattice point to the query direction.
///
/// FOUR CANDIDATES, NOT ONE, and this pack keeps all four rather than taking the
/// nearest. A soft disc whose radius stays under half the lattice spacing is
/// only ever covered by one dot, so the nearest would do -- but three species
/// deliberately CROWD their dots (vortex draws them to a pole, gather packs them
/// onto a ring, form scale can be wound down), and where dots crowd they overlap
/// and the union of four discs is the right picture where the nearest one is a
/// Voronoi cell with visible seams. The four are already computed. Using them
/// costs three comparisons.
///
/// THE MIRROR on the candidate latitude: a cell at the pole has corners whose
/// cos(theta) falls outside [-1, 1]. Reflecting them back rather than clamping
/// keeps the two corners distinct, so the polar dot is not counted twice.
///
/// WHY A 2 PI OFFSET IN PHI DOES NOT MATTER, which is the one thing that looks
/// fragile and is not: atan2 returns a longitude in (-pi, pi] while the lattice
/// speaks in [0, 2 pi). Shifting phi by 2 pi shifts the cell coordinates by
/// exactly (F_{k+1}, -F_k), and F_k F_{k+1} - F_{k+1} F_k = 0 -- the index, and
/// therefore the answer, is unchanged. The construction is periodic by
/// arithmetic, not by luck.
static MOLattice mo_lattice(float3 p, float n) {
    float phi = min(atan2(p.y, p.x), M_PI_F);
    float cosT = clamp(p.z, -1.0, 1.0);

    // The ring spacing at this latitude decides which Fibonacci level is the
    // right basis. Floored at 1e-6 so the poles give a finite log rather than a
    // NaN that would poison the whole pixel.
    float sin2 = max(1.0 - cosT * cosT, 1.0e-6);
    float k = max(2.0, floor(log(n * M_PI_F * 2.2360680 * sin2) / log(MO_PHI * MO_PHI)));
    float Fk = pow(MO_PHI, k) * 0.4472136;      // PHI^k / sqrt(5), Binet
    float F0 = round(Fk);
    float F1 = round(Fk * MO_PHI);

    // The two basis vectors, as (d phi, d cos theta) per index step.
    // The phi terms are written as frac((F+1)/PHI) - 1/PHI rather than as
    // frac(F/PHI) so the answer comes out as a SIGNED small angle: a step whose
    // longitude drifts backwards has to be able to say so, and frac() alone
    // would report it as nearly a full turn forwards.
    float a0 = MO_TAU * (mo_madfrac(F0 + 1.0, MO_INVP) - MO_INVP);
    float a1 = MO_TAU * (mo_madfrac(F1 + 1.0, MO_INVP) - MO_INVP);
    float b0 = -2.0 * F0 / n;
    float b1 = -2.0 * F1 / n;

    // Invert [[a0, a1], [b0, b1]] and floor: the cell this direction falls in.
    float det = a0 * b1 - a1 * b0;
    float inv = 1.0 / (abs(det) < 1.0e-12 ? 1.0e-12 : det);
    float2 rhs = float2(phi, cosT - (1.0 - 1.0 / n));
    float2 c = floor(float2(( b1 * rhs.x - a1 * rhs.y) * inv,
                            (-b0 * rhs.x + a0 * rhs.y) * inv));

    MOLattice L;
    for (int s = 0; s < 4; s++) {
        float2 cell = c + float2(float(s & 1), float(s >> 1));
        float ct = b0 * cell.x + b1 * cell.y + (1.0 - 1.0 / n);
        ct = clamp(ct, -1.0, 1.0) * 2.0 - ct;                 // the polar mirror
        float idx = clamp(floor(n * 0.5 - ct * n * 0.5), 0.0, n - 1.0);
        float ph = MO_TAU * mo_madfrac(idx, MO_INVP);
        float cz = 1.0 - (2.0 * idx + 1.0) / n;
        float sz = sqrt(max(1.0 - cz * cz, 0.0));
        L.q[s] = float3(cos(ph) * sz, sin(ph) * sz, cz);
        L.i[s] = idx;
    }
    return L;
}

/// ACCENT, and it is chosen by the dot's INDEX and nothing else.
///
/// That is the whole requirement: a dot that is jostled out of its seat, swept
/// to a pole, wound onto a thread or re-seated must keep its accent through all
/// of it, and two consecutive frames must agree. Hashing the index gives that
/// for free, because the index IS the dot's identity and it travels with it. A
/// hash of the position would have been one character shorter and would have
/// made the accents crawl over a rotating sphere like static.
///
/// The dial is scaled by 0.62 rather than used raw, so the roster's default of
/// 0.3 puts under a fifth of the lattice on the saturated stop. A third of the
/// ball refusing to reach cream would have flattened the very hierarchy the
/// accents are supposed to sit inside. The gate at the bottom is so that
/// accentShare = 0 means none, exactly, rather than the few dots whose hash
/// happens to land in the smoothstep's skirt.
static inline float mo_accent(float index, float share) {
    float sh = clamp(share, 0.0, 1.0);
    float thr = sh * 0.62;
    float h = mo_hash1(index, 704.0);
    return (1.0 - smoothstep(thr - 0.035, thr + 0.035, h)) * smoothstep(0.0, 0.06, sh);
}

/// THE ONE PLACE ENERGY BECOMES LIGHT, and every dot in this pack goes through
/// it, which is most of what keeps the family reading as one family.
///
/// The base ramp is the signal pack's: mo_tier spends the rail unevenly so an
/// empty pixel is ink to the bit, a dot's body is amber, and only a dot's lit
/// core reaches the pale specular.
///
/// The accent ramp is this pack's own. An accent walks the SAME energy onto a
/// band that starts at the shadow stop and tops out at 0.80, which is the tone's
/// saturated stop and one notch short of where the cream begins. So an accent
/// dot in full light is not a brighter dot: it is a dot that stayed gold while
/// its neighbours went pale, which is the only kind of accent a single-hue
/// palette can honestly have.
///
/// `accentFrac` is faded out at low energy before it is used. Without that, the
/// dying rim of an accent dot would sit at the shadow stop instead of falling to
/// ink, and every accent would wear a visible ring.
static inline float3 mo_lit(MOPalette pal, float e, float accentFrac,
                            float glow, float emis) {
    float G = max(glow, 0.0);
    // `glow` enters where it cannot lie: it scales the energy BEFORE the rail
    // walk, so a lower setting walks less far and reads cooler and deeper rather
    // than merely faded. At glow = 0 a third survives, because an indicator that
    // can be switched off by a dial is a bug and not a dial.
    float en = clamp(mo_knee(max(e, 0.0) * (0.35 + 0.65 * G), 0.92), 0.0, 1.0);
    float tier = mo_tier(en);
    float aF = clamp(accentFrac, 0.0, 1.0) * smoothstep(0.02, 0.24, en);
    float tRail = clamp(mix(tier, 0.30 + 0.50 * tier, aF), 0.0, 1.0);
    float3 col = mo_shade(pal, tRail);
    // Emission is gated to the specular, plus a smaller gate lower down for the
    // accents -- a saturated dot that emits nothing reads as a hole in the
    // lattice, which is the opposite of an accent.
    float em = emis * G * (smoothstep(0.72, 1.0, tRail)
                         + 0.60 * aF * smoothstep(0.44, 0.80, tRail));
    return col * (1.0 + em);
}

// MARK: - The species descriptor, and the two things a species owns

/// Everything the shared ball needs to know about which species it is drawing.
/// The four `a` slots and the one vector are the species' own working room: each
/// stitchable function reads its knobs, its clock and its state, works out what
/// it wants in whatever terms suit it, and leaves the numbers here. Nothing in
/// mo_warp or mo_level does arithmetic that belongs to a species' preamble.
struct MOSpec {
    int   kind;      // 0 breathe, 1 orbit, 2 glimmer, 3 vortex,
                     // 4 gather, 5 stir, 6 daybreak, 7 skein
    float n;         // lattice count
    float rad;       // base dot radius, as a chord on the unit sphere
    float accent;    // accentShare, straight from c3
    float back;      // how far the far hemisphere sinks
    float key;       // how much of the fixed key light this species wears
    float k0, k1;    // the species' own two character knobs
    float a0, a1, a2, a3;
    float3 vec;      // one direction, for the species that need one
    float t;         // the species clock, speed already in it
    float crest, wave, accord, settled, drive;   // the state read
};

/// WHERE THE DOTS SIT. Four of the eight species move their lattice, and all
/// four do it the same way: by warping the direction the lookup is done in,
/// never by moving the lattice itself. Warping the query is the only affordable
/// option -- there is no list of points to push around -- and it is also the
/// truer one, because it keeps every dot on the sphere and keeps the silhouette
/// exactly where it was. A dot's IDENTITY, and therefore its accent, travels
/// with it, because the index it comes back with is the index of the seat it
/// left.
///
/// The four that do nothing here (breathe, glimmer, daybreak, skein) say what
/// they have to say in the light instead. That is a real division: a species is
/// either moving its material or lighting it, and the ones that try both at once
/// were the ones that read as busy.
static float3 mo_warp(MOSpec sp, float3 p) {
    if (sp.kind == 1) {
        // ORBIT. A rotation about the lattice's own pole whose RATE depends on
        // latitude: the bands at the shear maxima run at about a tenth of the
        // rate of the ones at the minima, so they slide past each other the way
        // a gas planet's do. It is a rotation, so it preserves z exactly, which
        // means the band structure never smears -- each ring slides within
        // itself and the lattice stays a lattice.
        //
        // The angle is (rate * t + the drive's integrated turn) so RESPONDING
        // can accelerate the streaming without teleporting it, and the surge is
        // added as an ANGLE rather than folded into the rate for the same
        // reason: a gesture that multiplies t is not a gesture, it is a jump.
        float w = 0.55 + 0.45 * cos((1.4 + 4.2 * sp.k0) * M_PI_F * p.z);
        float lane = (p.z - sp.a3) * 3.3;
        float ang = -((sp.a0 * sp.t + sp.a1) * w + sp.a2 * exp(-lane * lane));
        float c = cos(ang), s = sin(ang);
        return float3(c * p.x - s * p.y, s * p.x + c * p.y, p.z);
    } else if (sp.kind == 3) {
        // VORTEX. Two things, and both are geometry.
        //
        // THE DRAW is a power law on the latitude: z = 2 u^e - 1 with u the
        // latitude mapped to 0...1 and e below one, which pulls every ring
        // toward the north pole and packs them tighter the further they go. The
        // lookup needs the INVERSE, which is the same law with 1/e, and that is
        // why this could be done at all: a monotone map of the latitude alone
        // has a closed-form inverse, so the whole lattice can be dragged up the
        // ball for the price of one pow.
        //
        // THE TWIST is a rotation about the same pole that grows with latitude,
        // so the rings that have been drawn furthest have also been wound
        // furthest and the lattice spirals into the crown instead of merely
        // sliding into it. Winding without drawing is a shear; drawing without
        // winding is a squeeze. Together they are a vortex.
        float u = clamp((clamp(p.z, -1.0, 1.0) + 1.0) * 0.5, 0.0, 1.0);
        float z0 = clamp(2.0 * pow(u, 1.0 / max(sp.a0, 0.25)) - 1.0, -1.0, 1.0);
        float rxy = sqrt(max(1.0 - z0 * z0, 0.0));
        float hl = length(p.xy);
        float2 h = (hl > 1.0e-5) ? p.xy / hl : float2(1.0, 0.0);
        float tw = -sp.a1 * (0.30 + 0.70 * u);
        float c = cos(tw), s = sin(tw);
        return float3((c * h.x - s * h.y) * rxy, (s * h.x + c * h.y) * rxy, z0);
    } else if (sp.kind == 4) {
        // GATHER. The ring first, then the dispersion on top of it.
        //
        // THE RING is the same trick as the vortex's draw, aimed at the equator
        // instead of a pole: z = sign(z) |z|^g with g above one pulls latitudes
        // toward zero, and the inverse is the same law with 1/g. As g opens the
        // rings pile onto the equator and the dots there stop being scattered
        // and start being a band, which is the arrival this species is for.
        //
        // THE DISPERSION is a smooth vector field added to the query direction
        // and then renormalised. At birth it is large enough to fold the lattice
        // over itself several times, which is a scatter; the settle law drains
        // it, and its floor never reaches zero, so a ringed orb at rest is still
        // breathing rather than frozen. A per-dot random offset would have been
        // the obvious way to disperse and it is not available here -- there is
        // no per-dot anything before the lookup -- but a smooth fold is the
        // better picture anyway: it disperses the lattice without destroying the
        // fact that it IS a lattice, so the convergence reads as the same dots
        // coming home rather than as one image dissolving into another.
        float z = clamp(p.z, -1.0, 1.0);
        float z0 = clamp(sign(z) * pow(abs(z), 1.0 / max(sp.a1, 0.20)), -1.0, 1.0);
        float rxy = sqrt(max(1.0 - z0 * z0, 0.0));
        float hl = max(length(p.xy), 1.0e-5);
        float3 seat = float3(p.xy / hl * rxy, z0);
        float3 d = p * 2.55 + float3(sp.a2, sp.a2 * 0.73, -sp.a2 * 0.41);
        float3 nv = float3(mo_noise3(d), mo_noise3(d + 31.7), mo_noise3(d + 77.3));
        return mo_unit(seat + nv * (sp.a0 * (0.12 + 0.92 * sp.k0)));
    } else if (sp.kind == 5) {
        // STIR. The same fold, an order of magnitude smaller and driven by the
        // flourish clock instead of by an arc: the dots are lifted off their
        // seats, carried a little way, and set back down. The field drifts while
        // it does it, so no two jostles put a dot in the same place twice.
        float3 d = p * 3.35 + float3(sp.a2, sp.a2 * 0.61, -sp.a2 * 0.87);
        float3 nv = float3(mo_noise3(d), mo_noise3(d + 19.1), mo_noise3(d + 53.9));
        return mo_unit(p + nv * (sp.a0 * (0.040 + 0.135 * sp.k0)));
    }
    return p;
}

/// HOW BRIGHTLY EACH DOT BURNS, and how big it is while it burns. Returns
/// (level, radius scale). Level 1 is a dot doing nothing in particular; the
/// shading of the ball, the accent decision and the rail walk all happen
/// downstream, so a species can say what it means here in plain multiples and
/// never has to know about colour.
///
/// `q` is the dot's seat on the lattice, in the body frame -- use it for
/// anything that belongs to the SPHERE (a latitude band, a winding, a ring).
/// `view` is where the pixel actually is, in view space -- use it for anything
/// that belongs to the VIEWER (a light, a wavefront, a sweep). Confusing the two
/// is the difference between a terminator that crosses a turning planet and one
/// that is painted on it.
static float2 mo_level(MOSpec sp, float3 q, float3 view, float index) {
    float lvl = 1.0;
    float rs  = 1.0;

    if (sp.kind == 0) {
        // BREATHE. The inhale is carried by the dots' SIZE first and their
        // brightness second, in that order and by that margin, because a
        // luminance pulse on its own is the motif the house bans: what makes
        // this legal is that the concept literally is a rhythm and that the
        // rhythm is expressed as the lattice opening, not as a lamp.
        //
        // DEPTH CARRIES THE BREATH. The phase is lagged by the dot's view depth,
        // so the inhale reaches the front of the ball a beat before it reaches
        // the back and the breath is seen travelling THROUGH the sphere. That
        // one term is the difference between a sphere breathing and a circle
        // pulsing.
        float br = 0.5 + 0.5 * sin(sp.t * 0.66 - view.z * sp.a1);
        rs  = 1.0 + sp.a0 * (0.74 * br - 0.35);
        lvl = 0.88 + 0.30 * sp.a0 * br;
    } else if (sp.kind == 1) {
        // ORBIT. The bands have to be VISIBLE as bands or the differential
        // rotation is just a smear, so the same latitude cosine that sets a
        // ring's speed also sets its weight: the fast lanes are the bright ones.
        // This is also where SUCCESS lands for this species -- accord evens the
        // weights out below, which is the honest way to say "in accord" when the
        // deviation itself is a rate and cannot be touched.
        float band = 0.5 + 0.5 * cos((1.4 + 4.2 * sp.k0) * M_PI_F * q.z);
        lvl = 0.72 + 0.52 * band;
        rs  = 0.92 + 0.17 * band;
    } else if (sp.kind == 2) {
        // GLIMMER. Each dot owns a phase, hashed from its index, and lights when
        // its turn comes round. Because the hash is scattered the ORDER is
        // scattered, so what the eye follows is a constellation being counted
        // rather than a wave crossing a ball -- which is exactly what separates
        // this from mo_daybreak. `spread` sets how sharp the von Mises bump is,
        // which is really how many dots are lit at once: a hard bump is one or
        // two at a time and a soft one is a third of the sphere glimmering.
        //
        // The floor at 0.44 is not decoration. A dot waiting its turn still has
        // to be a dot, or the sphere disassembles itself between sparkles.
        float u = sp.a0 - mo_hash1(index, 21.0);
        u -= floor(u);
        float spark = exp(sp.a1 * (cos(MO_TAU * u) - 1.0));
        // THE CHAIN, and it is the gesture: for a couple of seconds the order
        // stops being scattered and becomes SPATIAL, a run of light travelling
        // the ball and handing off dot to dot. Play, because the species spends
        // the rest of its life refusing to do that.
        float ch = (dot(view, MO_SWEEP) - sp.a3) * 3.7;
        float s = max(spark, sp.a2 * exp(-ch * ch));
        lvl = 0.44 + 1.06 * s;
        rs  = 0.86 + 0.32 * s;
    } else if (sp.kind == 3) {
        // VORTEX. The draw compresses the rings, and compression is DENSITY: the
        // Jacobian of the latitude law says exactly how much, so the crowded
        // rings brighten and their dots pull in tight rather than merging into a
        // smear. That is the reason the crown reads as a crown of dots and not
        // as a bright cap -- the same number that makes them crowd makes them
        // small.
        float u0 = clamp((q.z + 1.0) * 0.5, 1.0e-4, 1.0);
        float J = max(sp.a0 * pow(u0, sp.a0 - 1.0), 0.10);
        lvl = 0.64 + 0.36 * clamp(1.0 / J, 0.55, 2.60);
        rs  = clamp(pow(J, 0.34), 0.60, 1.22);
    } else if (sp.kind == 4) {
        // GATHER. Where a dot ENDS UP under the ring law decides its light, so
        // the band brightens as it forms rather than being lit into existence.
        // The Jacobian does the same job it does in the vortex: the ring is
        // dense, so its dots shrink, so it stays countable.
        float az = max(abs(q.z), 1.0e-3);
        float za = sign(q.z) * pow(az, sp.a1);
        float ring = exp(-(za / 0.30) * (za / 0.30));
        float J = clamp(sp.a1 * pow(az, sp.a1 - 1.0), 0.06, 4.0);
        lvl = 0.56 + 0.26 * (1.0 - sp.a3) + 0.90 * ring * sp.a3;
        rs  = clamp(pow(J, 0.30), 0.58, 1.20);
    } else if (sp.kind == 5) {
        // STIR. A dot in the air is dimmer and smaller than a dot in its seat --
        // that is the whole shading idea, and it is what makes the settle read
        // as a settle rather than as a wobble. Each dot takes its own share of
        // the jostle from its index hash, so they do not all lift and land
        // together like a rehearsed chorus.
        float air = sp.a0 * (0.30 + 0.70 * mo_hash1(index, 55.0));
        lvl = 1.00 - 0.36 * air;
        rs  = 1.00 - 0.24 * air;
    } else if (sp.kind == 6) {
        // DAYBREAK. The only species that does not wear the pack's fixed key
        // light, because here the light IS the species: a sun direction that
        // circles the ball, so the terminator sweeps the face and time enters
        // where a coordinate is read rather than as a brightness on a timer.
        //
        // The night side floors at 0.30 rather than going out. A planet's night
        // side is not empty, and more to the point an indicator that goes half
        // dark for half its cycle reads as broken.
        //
        // The DAWN LINE is the second term: dots right at the terminator are the
        // brightest thing in the frame, which is true of a real sunrise seen
        // from space and is also what gives this species a nameable figure -- a
        // bright arc crossing a dim ball, legible at 20 pt.
        float x = dot(view, sp.vec);
        float day = smoothstep(-sp.a3 * 1.5, sp.a3 * 1.5, x);
        float dw = x / sp.a3;
        float dawn = exp(-dw * dw);
        lvl = 0.30 + 0.94 * day + 0.58 * dawn * sp.a0;
        rs  = 0.90 + 0.22 * day + 0.16 * dawn;
    } else {
        // SKEIN. One curve wrapping the ball -- longitude minus a multiple of
        // latitude, which is the spherical spiral a thread takes when you wind
        // it round something -- and the dots near it are the strung ones.
        //
        // The distance to the thread is the phase error DIVIDED BY the phase
        // gradient, which matters: without it the band would be measured in
        // radians of phase and would balloon near the poles where a radian of
        // longitude is almost no distance at all. With it the thread has the
        // same width everywhere, which is what a thread has.
        //
        // The BEAD is a packet of light running the winding pole to pole, and it
        // is the reason this is not a static decoration: something is travelling
        // the thread, so the thread has a direction and a length.
        float z = clamp(q.z, -1.0, 1.0);
        float lat = asin(z);
        float sinT = max(sqrt(max(1.0 - z * z, 0.0)), 0.20);
        float s = atan2(q.y, q.x) - sp.a0 * lat - sp.a1;
        s -= MO_TAU * floor(s / MO_TAU + 0.5);
        float dth = abs(s) / sqrt(1.0 / (sinT * sinT) + sp.a0 * sp.a0);
        float thr = 1.0 - smoothstep(sp.a3 * 0.45, sp.a3 * 1.70, dth);
        // `trail` is the bead's length: a tight spark at zero, a long glowing
        // stretch of thread at one. It is read straight off the knob here rather
        // than precomputed because it is the one thing about the bead that is a
        // shape and not a position.
        float bd = (lat - sp.a2) / (0.24 + 0.52 * sp.k1);
        float bead = exp(-bd * bd);
        lvl = 0.32 + 0.74 * thr + 0.82 * thr * bead;
        rs  = 0.86 + 0.22 * thr + 0.16 * thr * bead;
    }

    // SUCCESS, in two movements, and both of them travel through what is already
    // there rather than over it. First the WAVEFRONT: a band of light crossing
    // the ball along MO_SWEEP, brightening each dot as it passes and leaving it
    // where it found it. Then the ACCORD: every dot pulled toward one common
    // brightness and one common size, so for a breath the lattice is even,
    // finished, and unmistakably the same lattice. Then it lets go.
    float fr = (dot(view, MO_SWEEP) - sp.wave) * 3.33;
    lvl += sp.crest * 1.35 * exp(-fr * fr);
    lvl = mix(lvl, 1.12, sp.accord * 0.72);
    rs  = mix(rs,  1.05, sp.accord * 0.60);
    lvl *= 1.0 + 0.24 * sp.settled;

    return float2(max(lvl, 0.0), max(rs, 0.12));
}

// MARK: - The ball

/// One hemisphere's worth of dots, accumulated.
///
/// COVERAGE IS A MAX and everything else is a coverage-weighted MEAN, and the
/// pairing is deliberate. Max is the union of soft discs, which is what
/// overlapping dots actually look like -- a sum would double the brightness
/// where two crowded dots touch and put a bright bead at every contact. The
/// means are for the properties that have to be continuous across the seam
/// between two neighbouring dots: if the accent were taken from the nearest dot
/// alone it would flip along the midline between an accent and a plain one, and
/// a flip in the middle of the picture is a visible edge. Weighted by coverage,
/// it crosses smoothly and the seam disappears.
struct MOHemi { float cov, energy, accent; };

static MOHemi mo_hemi(MOSpec sp, MOLattice L, float3 look, float3 view,
                      float radScale, float softFloor, bool isBack) {
    float cov = 0.0, wsum = 0.0, coreW = 0.0, accW = 0.0, litW = 0.0;
    for (int s = 0; s < 4; s++) {
        float3 q = L.q[s];
        float2 md = mo_level(sp, q, view, L.i[s]);
        float rad = sp.rad * radScale * md.y;
        // The edge is never allowed to be thinner than about a pixel and a half.
        // At 300 pt the first term wins and a dot has a soft, deliberate rim; at
        // 20 pt the second does, and the dot goes slightly soft rather than
        // crawling with aliasing, which is the failure that would read as noise.
        float soft = max(0.32 * rad, softFloor);
        float d = length(look - q);
        float c = 1.0 - smoothstep(max(rad - soft, 0.0), rad + soft, d);
        float u = clamp(1.0 - d / max(rad, 1.0e-4), 0.0, 1.0);
        cov = max(cov, c);
        wsum += c;
        coreW += c * smoothstep(0.34, 0.96, u);
        accW  += c * mo_accent(L.i[s], sp.accent);
        litW  += c * md.x;
    }
    float inv = 1.0 / max(wsum, 1.0e-4);
    float core = coreW * inv;
    MOHemi o;
    o.cov = cov;
    // Accents are a front-hemisphere privilege. A saturated dot seen through the
    // ball is not an accent, it is a distraction behind the thing you are
    // looking at.
    o.accent = isBack ? 0.0 : accW * inv;
    // THE DOT'S OWN VALUE RAMP: an amber BODY with a CREAM PEAK at its centre.
    // The back hemisphere gets almost none of it, because a dot behind the
    // sphere that carries a specular is a dot that is not behind anything.
    o.energy = cov * (litW * inv) * (isBack ? (0.84 + 0.22 * core)
                                            : (0.60 + 0.72 * core));
    return o;
}

/// The frame. `bodyFromView` takes a direction in view space to the lattice's
/// own frame, which is where the lookup lives.
///
/// `tip` is measured so that the lattice's pole lands mostly UP the screen with
/// a little lean toward the viewer -- remember +y is down in this uv frame, so
/// up is negative. A pole pointed straight at the camera turns the fibonacci
/// spiral into a rosette, which is a beautiful still and a dead animation: you
/// see the spiral instead of the ball. A pole up and slightly forward shows a
/// polar region, an equator and a limb all at once, which is what makes a
/// rotation legible.
static inline float3x3 mo_frame(float spin, float tip) {
    float c = cos(tip), s = sin(tip);
    float C = cos(spin), S = sin(spin);
    return float3x3(float3(C, -S, 0.0),
                    float3(S * c, C * c, -s),
                    float3(S * s, C * s, c));
}

/// THE BALL. Every species ends here, and this is the whole picture.
static half4 mo_orb(MOSpec sp, float3x3 bodyFromView, float R,
                    float2 position, float2 size, float pixelScale,
                    half4 inkColor, half4 toneColor,
                    float hueShift, float depth, float glow, float emis) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float3 inkLin = mo_srgb_to_linear(float3(inkColor.rgb));

    float radiusPx = max(R * max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0), 2.0);
    float pxS = 1.0 / radiusPx;                  // one pixel, in sphere radii
    float sEdge = max(0.030, 2.4 * pxS);         // the limb's own softness

    float2 s2 = uv / max(R, 1.0e-3);
    float rs2 = length(s2);

    // THE EARLY OUT. Outside the silhouette there is nothing to look up and the
    // answer is the ink itself, to the bit. That is a little under half of the
    // clipped disc and all four corners of the rectangle, and it is where this
    // pack's lattice cost goes to zero: the expensive part of the shader only
    // ever runs on the ball.
    if (rs2 >= 1.0 + sEdge) {
        return mo_out(inkLin, position * pixelScale);
    }

    // THE CAMERA. A real ray cast against a unit sphere from an eye six radii
    // back, rather than the orthographic sqrt(1 - r^2) that would have been one
    // line. Six is a slight perspective on purpose: it hides about a twelfth of
    // the far side behind the limb, so the visible cap is a little less than a
    // hemisphere and the lattice is seen curving AWAY at the edge instead of
    // running to a hard rim. Small effect, and it is most of what stops a dot
    // sphere reading as a dot disc.
    //
    // `w` is chosen so the silhouette lands exactly at |s| = 1: the tangent ray
    // condition gives w = D / sqrt(D^2 - 1) in closed form, so the ball fills
    // the radius the composition asked for at any D.
    const float D = 6.0;
    const float W = 1.0141851;                   // 6 / sqrt(35)
    float3 O = float3(0.0, 0.0, D);
    float3 dir = normalize(float3(s2 * W, 0.0) - O);
    float b = dot(O, dir);
    float sq = sqrt(max(b * b - (D * D - 1.0), 0.0));
    float3 pNear = normalize(O + dir * (-b - sq));
    float3 pFar  = normalize(O + dir * (-b + sq));

    // The key light, wrapped and raised to 1.7 so the terminator falls the way a
    // sphere's does rather than the way a cone's does. The lit shoulder passes
    // 1.2 because the value hierarchy needs somewhere for the cream to come
    // from, and the shaded flank floors at 0.26 rather than at zero because a
    // dot on the dark side of a ball is still a dot.
    //
    // The saturate is not decoration and it is not defensive clutter: it is the
    // INVARIANT that the pow below depends on. Both arguments are unit vectors,
    // so the dot product is in [-1, 1] and lam is in [0, 1] by construction --
    // but "by construction" is exactly the reasoning that let a light vector
    // 2.5% too long put a NaN hole in every species of this pack, and float
    // rounding can put a unit dot product a bit past 1 on its own. Stating the
    // range here means no future light direction, and no rounding, can bring the
    // hole back. See MO_KEY.
    float lamF = saturate(0.5 + 0.5 * dot(pNear, MO_KEY));
    float lamB = saturate(0.5 + 0.5 * dot(pFar,  MO_KEY));
    float keyF = mix(1.0, 0.26 + 0.98 * pow(lamF, 1.7), sp.key);
    float keyB = mix(1.0, 0.44 + 0.60 * pow(lamB, 1.7), sp.key);

    float3 lookF = mo_warp(sp, bodyFromView * pNear);
    float3 lookB = mo_warp(sp, bodyFromView * pFar);

    // Nearer dots are bigger, and the far hemisphere is shrunk again on top of
    // that. Two cues for the same fact, because at 20 pt only one of them
    // survives and it is not always the same one.
    float radF = 0.62 + 0.44 * (0.5 + 0.5 * pNear.z);
    float radB = (0.62 + 0.44 * (0.5 + 0.5 * pFar.z)) * 0.88;

    MOHemi fr = mo_hemi(sp, mo_lattice(lookF, sp.n), lookF, pNear, radF, 1.5 * pxS, false);
    MOHemi bk = mo_hemi(sp, mo_lattice(lookB, sp.n), lookB, pFar,  radB, 1.5 * pxS, true);

    // THE BODY. A very faint warm presence between the dots, about a twentieth
    // of a lit dot's energy and shaded by the same key. Without it the figure is
    // a handful of confetti that happens to be arranged on a sphere; with it
    // there is an object, and the figure law is satisfied at 20 pt where the
    // individual dots are three pixels wide.
    float body = 0.050 + 0.062 * keyF;

    // The far hemisphere is dimmed hard and then OCCLUDED by whatever is in
    // front of it, which is the depth cue that costs nothing and does the most
    // work: back dots appear in the gaps between front dots and disappear
    // behind them, and the eye reads a solid ball from that alone.
    float sil = 1.0 - smoothstep(1.0 - sEdge, 1.0, rs2);
    float e = (fr.energy * keyF + bk.energy * keyB * sp.back * (1.0 - fr.cov) + body) * sil;

    MOPalette pal = mo_palette(inkColor, toneColor, hueShift, depth);
    float3 field = mo_lit(pal, e, fr.accent * smoothstep(0.05, 0.35, fr.cov), glow, emis);

    return mo_finish(field, inkLin, mo_containment(uv, 0.84), position, pixelScale);
}

/// The base dot radius, as a chord on the unit sphere. A fibonacci set of n
/// points has a nearest-neighbour spacing of about 3.81/sqrt(n), so half that --
/// the largest a dot can be before it touches its neighbour -- is 1.90/sqrt(n).
/// The dial runs from 0.68 to 1.72 of that, which is to say from clearly
/// separate beads to a lattice just short of closing up, and never past it: the
/// species that crowd their dots do it deliberately and should be the only
/// places dots ever merge.
static inline float mo_radius(float n, float dotSize) {
    return (0.34 + 0.52 * clamp(dotSize, 0.0, 1.0)) * 2.0 * rsqrt(max(n, 4.0));
}

// MARK: - 1. Breathe

// BREATHE. The resting orb, and the one the other seven are variations on.
//
// Nothing here does anything clever. The lattice opens and closes, the sphere
// turns, and that is the entire species -- which is the point: this is the state
// a thinking indicator sits in for most of its life, and the bar for a resting
// animation is that a person can leave it running in the corner of a chat for
// twenty minutes without ever being asked to look at it.
//
// THE ONE IDEA is that the breath has DEPTH. The phase is lagged by each dot's
// distance from the viewer, so the inhale reaches the near face of the ball
// about a third of a cycle before it reaches the far one, and what the eye sees
// is a wave passing through a solid rather than a circle changing size. `depth`
// is that lag, and at zero the ball breathes as one piece, which is the duller
// but perfectly honest end of the dial.
//
// WHY A PULSE IS ALLOWED HERE. The house verbs are flow and settle and pulsing
// luminance is not a default motif -- but the exception the rule states is a
// concept that literally IS a rhythm, and this is that concept. Even so the
// brightness is the junior partner: the dots' SIZE carries three quarters of the
// breath and their light carries the rest, so the ball opens rather than
// brightens. The sphere's own radius moves too, by four per cent, which is small
// enough that nobody sees it happen and large enough that everybody feels it.
//
// THE GESTURE is one deeper breath, arriving every four to nine seconds and
// never on a beat you can count.
[[ stitchable ]] half4 mo_breathe(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float t = time * max(speed, 0.0);
    MOState st = mo_state(stateIndex, stateTau);
    float4 fl = mo_flourish(t, 5.0);

    float breath    = clamp(c0, 0.0, 1.0);
    float depthFade = clamp(c1, 0.0, 1.0);

    MOSpec sp;
    sp.kind = 0;
    sp.n    = mo_count(size, formScale);
    sp.rad  = mo_radius(sp.n, c2);
    sp.accent = c3;
    sp.back = 0.72;
    sp.key  = 1.0;
    sp.k0 = breath; sp.k1 = depthFade;
    // The deeper breath is a swell of the amplitude, not a change of the rate:
    // a breath that speeds up is a person startled, and this species is at rest.
    sp.a0 = (0.22 + 0.55 * breath) * (1.0 + 0.62 * fl.x);
    // The lag is taken out on accord, which is this species' way of saying the
    // lattice has come into agreement: the whole ball breathing as one piece.
    sp.a1 = (0.45 + 1.45 * depthFade) * (1.0 - 0.85 * st.accord);
    sp.a2 = 0.0; sp.a3 = 0.0;
    sp.vec = float3(0.0, 0.0, 1.0);
    sp.t = t;
    sp.crest = st.crest; sp.wave = st.wave; sp.accord = st.accord;
    sp.settled = st.settled; sp.drive = st.drive;

    // The slowest spin in the pack, because rest is the brief. RESPONDING more
    // than doubles it, through the integrated turn so the ball accelerates from
    // exactly where it was standing.
    float spin = t * 0.32 + 0.085 * mo_fbm1(t * 0.115, 2, 5.0) + 0.50 * st.turn;
    float tip  = 1.2708 + 0.055 * sin(t * 0.083);

    float R = MO_R * (1.0 + 0.042 * sp.a0 * (0.5 + 0.5 * sin(t * 0.66)));
    return mo_orb(sp, mo_frame(spin, tip), R, position, size, pixelScale,
                  inkColor, toneColor, hueShift, depth, glow, 0.32);
}

// MARK: - 2. Orbit

// ORBIT. Latitude bands streaming around the sphere at neighbouring speeds.
//
// The reference for this is a gas planet, not a gyroscope. What makes Jupiter
// legible from a hundred million miles is not that it spins -- everything spins
// -- but that its belts spin at DIFFERENT rates, so the eye has something to
// measure the motion against. A uniformly rotating dot sphere is almost
// motionless to look at; the same sphere with its rings sliding past each other
// is unmistakably in motion even when the net rotation is slow.
//
// HOW IT IS DONE, and why it is exact rather than approximate: the shear is a
// rotation about the lattice's own pole whose angle depends only on latitude. A
// rotation about z preserves z, so every ring slides strictly WITHIN itself.
// Nothing is stretched, nothing crosses a neighbour, and the lattice is still a
// lattice at every instant -- which it would not be if the bands were made by
// displacing the dots along a flow field. `bands` sets how many belts the
// cosine cuts (one and a half to nearly six across the ball, which is the range
// where a belt is wide enough to hold three or four rings of dots) and `flow`
// sets the spread of rates.
//
// THE BELTS ARE VISIBLE because the same cosine that sets a ring's speed sets
// its weight: the fast lanes are the bright ones. Speed alone is a slow read at
// 20 pt; speed plus value is instant.
//
// THE GESTURE is one belt breaking ranks -- a gaussian in latitude that runs a
// single band a radian ahead of its neighbours and eases it back into line.
[[ stitchable ]] half4 mo_orbit(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float t = time * max(speed, 0.0);
    MOState st = mo_state(stateIndex, stateTau);
    float4 fl = mo_flourish(t, 12.0);

    float bands = clamp(c0, 0.0, 1.0);
    float flow  = clamp(c1, 0.0, 1.0);

    float rate = 0.16 + 0.40 * flow;

    MOSpec sp;
    sp.kind = 1;
    sp.n    = mo_count(size, formScale);
    sp.rad  = mo_radius(sp.n, c2);
    sp.accent = c3;
    sp.back = 0.72;
    sp.key  = 1.0;
    sp.k0 = bands; sp.k1 = flow;
    sp.a0 = rate;
    // RESPONDING: the belts run. The extra streaming is the integral of the
    // drive ramp, so entering the state leans the whole atmosphere forward
    // instead of jumping it to a new angle.
    sp.a1 = rate * 1.35 * st.turn;
    sp.a2 = fl.x * 0.95;                     // the breaking belt, as an angle
    sp.a3 = (fl.z - 0.5) * 1.70;             // which one it is
    sp.vec = float3(0.0, 0.0, 1.0);
    sp.t = t;
    sp.crest = st.crest; sp.wave = st.wave; sp.accord = st.accord;
    sp.settled = st.settled; sp.drive = st.drive;

    float spin = t * 0.30 + 0.075 * mo_fbm1(t * 0.109, 2, 12.0) + 0.44 * st.turn;
    float tip  = 1.2708 + 0.050 * sin(t * 0.071);

    return mo_orb(sp, mo_frame(spin, tip), MO_R, position, size, pixelScale,
                  inkColor, toneColor, hueShift, depth, glow, 0.32);
}

// MARK: - 3. Glimmer

// GLIMMER. A constellation being counted.
//
// Every dot owns a phase, hashed from its lattice index, and lights when its
// turn comes round. Because the hash is scattered the ORDER is scattered: light
// appears here, then over there, then somewhere behind, and the eye keeps trying
// to find the rule and keeps not finding it. That is the whole species, and it
// is deliberately the opposite of mo_daybreak, which lights the same lattice in
// strict spatial order. Same ball, same dots, two entirely different pictures,
// and the only difference between them is whether the sequence is in space or in
// a hash.
//
// THE BUMP is von Mises, exp(k(cos - 1)): periodic, smooth everywhere, and its
// width is one number. A fract() sawtooth would have been cheaper and has a step
// in it, and a step is a hard edge on an organic form. `spread` is that width,
// which is really "how many at once" -- at zero, one or two dots are lit and the
// ball is a dark constellation with a couple of stars in it; at one, a third of
// the lattice is shimmering.
//
// THE FLOOR at 0.44 is the load-bearing number. A dot waiting its turn is still
// a dot, and the first cut of this let unlit dots fall to nearly nothing, which
// disassembled the sphere between sparkles: what was left was a scatter of
// unrelated lights and no object at all. The figure law is not suspended because
// a species is about intermittency.
//
// THE GESTURE is a CHAIN: for a couple of seconds the order stops being
// scattered and becomes spatial, and a run of light travels the ball handing off
// from dot to dot. Play, because the species spends the rest of its life
// refusing to do exactly that.
[[ stitchable ]] half4 mo_glimmer(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float t = time * max(speed, 0.0);
    MOState st = mo_state(stateIndex, stateTau);
    float4 fl = mo_flourish(t, 21.0);

    float sparkle = clamp(c0, 0.0, 1.0);
    float spread  = clamp(c1, 0.0, 1.0);

    float rate = 0.13 + 0.26 * sparkle;

    MOSpec sp;
    sp.kind = 2;
    sp.n    = mo_count(size, formScale);
    sp.rad  = mo_radius(sp.n, c2);
    sp.accent = c3;
    sp.back = 0.66;
    sp.key  = 1.0;
    sp.k0 = sparkle; sp.k1 = spread;
    // The counting phase, with RESPONDING added as an integrated turn rather
    // than as a rate multiplier: the count gets quicker, it does not restart.
    sp.a0 = t * rate + rate * 1.10 * st.turn;
    // Wider on accord, so at the top of a success every dot is lit at once --
    // which for this species is exactly what "the lattice completes" means.
    sp.a1 = mix(mix(24.0, 5.0, spread), 0.9, st.accord);
    sp.a2 = fl.x;                            // the chain
    sp.a3 = 1.15 - 2.30 * fl.y;              // where along the ball it has got to
    sp.vec = float3(0.0, 0.0, 1.0);
    sp.t = t;
    sp.crest = st.crest; sp.wave = st.wave; sp.accord = st.accord;
    sp.settled = st.settled; sp.drive = st.drive;

    float spin = t * 0.34 + 0.090 * mo_fbm1(t * 0.121, 2, 21.0) + 0.46 * st.turn;
    float tip  = 1.2708 + 0.060 * sin(t * 0.091 + 2.1);

    return mo_orb(sp, mo_frame(spin, tip), MO_R, position, size, pixelScale,
                  inkColor, toneColor, hueShift, depth, glow, 0.36);
}

// MARK: - 4. Vortex

// VORTEX. The lattice drawn up toward a pole and twisted as it goes.
//
// TWO GEOMETRIES, and neither one alone is a vortex. The DRAW is a power law on
// the latitude that pulls every ring toward the north pole and packs them
// tighter the further they travel; on its own that is a squeeze. The TWIST is a
// rotation about the same pole that grows with latitude, so the rings that have
// been drawn furthest have also been wound furthest; on its own that is a shear.
// Together the lattice spirals into a crown, which is the thing the roster asked
// for and which neither term can say by itself.
//
// WHY IT IS AFFORDABLE. Both maps depend on the latitude alone and are monotone,
// so both have closed-form inverses -- one pow and one rotation -- and the whole
// lattice can be dragged up the ball for the price of a query warp. There is no
// per-dot anything, before or after.
//
// THE CROWN STAYS COUNTABLE, and this is the number that took the longest to
// find. Compression is density: where the rings pile up, the dots would merge
// into a bright cap and the species would stop being a dot sphere at its most
// interesting moment. So the Jacobian of the latitude law -- which says exactly
// how much a ring has been compressed -- does two jobs at once: it brightens the
// crowded rings, and it SHRINKS their dots by the same measure. The crown gets
// denser and brighter and stays a crown of dots.
//
// DRAWN AND RELEASED. A thirty-three second beat winds the whole thing up and
// lets it back down, and at the bottom of the beat the exponent is exactly one
// and the twist is exactly zero: the identity map, the plain rotating lattice.
// The species passes through its own resting state twice a minute, which is what
// stops a strong gesture becoming a permanent pose.
[[ stitchable ]] half4 mo_vortex(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float t = time * max(speed, 0.0);
    MOState st = mo_state(stateIndex, stateTau);
    float4 fl = mo_flourish(t, 34.0);

    float swirl = clamp(c0, 0.0, 1.0);
    float pole  = clamp(c1, 0.0, 1.0);

    // The beat, plus the gesture riding on it: the swirl bites harder for a
    // second and a half and lets go. Accord releases the whole thing, which for
    // this species is the lattice snapping back to its even seats -- the most
    // literal reading of "every dot briefly in accord" in the pack.
    float beat = (0.5 + 0.5 * sin(t * 0.187 - 1.10)) * (1.0 - 0.82 * st.accord)
               + 0.26 * fl.x;
    beat = clamp(beat, 0.0, 1.15);

    MOSpec sp;
    sp.kind = 3;
    sp.n    = mo_count(size, formScale);
    sp.rad  = mo_radius(sp.n, c2);
    sp.accent = c3;
    sp.back = 0.70;
    sp.key  = 1.0;
    sp.k0 = swirl; sp.k1 = pole;
    // The forward exponent. One is the identity; 0.50 lifts the equator to about
    // twenty-three degrees north, which is as far as the lattice can be dragged
    // before the southern rings thin out enough to read as a hole.
    sp.a0 = mix(1.0, 0.50, clamp(pole * beat, 0.0, 1.0));
    // RESPONDING tightens the winding: the vortex stops idling and pulls.
    sp.a1 = (0.80 + 3.40 * swirl) * beat * (1.0 + 0.55 * st.drive);
    sp.a2 = 0.0; sp.a3 = 0.0;
    sp.vec = float3(0.0, 0.0, 1.0);
    sp.t = t;
    sp.crest = st.crest; sp.wave = st.wave; sp.accord = st.accord;
    sp.settled = st.settled; sp.drive = st.drive;

    float spin = t * 0.36 + 0.070 * mo_fbm1(t * 0.104, 2, 34.0) + 0.48 * st.turn;
    // A shade more lean than the rest of the pack, because a vortex is about a
    // pole and a pole you cannot see is a pole that is not in the picture.
    float tip  = 1.1900 + 0.055 * sin(t * 0.079 + 0.7);

    return mo_orb(sp, mo_frame(spin, tip), MO_R, position, size, pixelScale,
                  inkColor, toneColor, hueShift, depth, glow, 0.33);
}

// MARK: - 5. Gather

// GATHER. Dispersion converging into one bright ring, and the only species in
// this pack with an arrival, so the only one that reads `epoch`.
//
// THE ARC IS A LAW, NOT AN ANIMATION. mo_settle_law states the scramble as a
// SPEED and hands back its exact integral, so the field's position at any t is
// the position the animation would have reached. No frame remembers the last
// one; a screenshot rig, a scrubbed slider and a resumed app all land on the
// same picture. Five and a half seconds is the tempo of an answer arriving:
// long enough that the search is legible, short enough that a chat UI is not
// made to wait. The house rate dial stays OUT of it, the way the pour keeps
// exhaleTime in real seconds, so a slower field still settles when it says it
// will.
//
// THE TWO HALVES OF THE ARC pull in opposite directions and that is the design.
// The DISPERSION is a smooth vector fold added to the query direction: at birth
// it is large enough to turn the lattice over itself several times, which reads
// as a scatter, and the law drains it. The RING is a power law on the latitude
// that pulls every ring of dots toward the equator, opening as the scatter
// closes. So the ball goes from a scrambled cloud to a packed band, and the two
// motions overlap in the middle where it looks like dots finding each other.
//
// WHY A SMOOTH FOLD AND NOT A PER-DOT SCATTER. There is no per-dot anything
// before the lookup -- that is the whole bargain the inverse mapping strikes --
// so a random offset per dot is simply not available. It turned out to be the
// better picture anyway: a smooth fold disperses the lattice without destroying
// the fact that it IS a lattice, so the convergence reads as the same dots
// coming home rather than as one image dissolving into a different one.
//
// RINGED IS NOT STOPPED. The scatter floors at about a twentieth of its birth
// amplitude and the fold's drift keeps advancing at the law's hold rate forever,
// so a settled ring shivers the way a held note does. A field that stops dead is
// a frozen image.
//
// THE GESTURE is a shiver that runs round the finished ring.
[[ stitchable ]] half4 mo_gather(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float t = time * max(speed, 0.0);
    MOState st = mo_state(stateIndex, stateTau);
    float4 fl = mo_flourish(t, 47.0);

    float pull = clamp(c0, 0.0, 1.0);
    float ring = clamp(c1, 0.0, 1.0);

    float tau = max(time - epoch, 0.0);
    float3 law = mo_settle_law(tau, 5.50);
    // SUCCESS carries the arc home: whatever is left of the scatter is taken out
    // and the ring closes completely, which is this species' own physics for the
    // lattice completing.
    float arc = clamp(max(1.0 - law.z, st.accord), 0.0, 1.0);

    MOSpec sp;
    sp.kind = 4;
    sp.n    = mo_count(size, formScale);
    sp.rad  = mo_radius(sp.n, c2);
    sp.accent = c3;
    sp.back = 0.72;
    sp.key  = 1.0;
    sp.k0 = pull; sp.k1 = ring;
    // The scatter, and the floor is the alive-at-rest clause written as a number.
    sp.a0 = (law.z * (1.0 - 0.92 * st.accord) + 0.045) * (1.0 + 0.30 * fl.x);
    // The ring's power law. RESPONDING packs it tighter: an answer being
    // delivered is an answer whose parts have stopped moving apart.
    sp.a1 = 1.0 + (0.60 + 2.00 * ring) * arc * (1.0 + 0.35 * st.drive);
    // The fold's own drift, taken from the law's INTEGRAL so it slows exactly the
    // way the scatter does and then keeps creeping forever at the hold rate.
    sp.a2 = law.y * 0.95 + 0.55 * fl.x;
    sp.a3 = arc;
    sp.vec = float3(0.0, 0.0, 1.0);
    sp.t = t;
    sp.crest = st.crest; sp.wave = st.wave; sp.accord = st.accord;
    sp.settled = st.settled; sp.drive = st.drive;

    float spin = t * 0.33 + 0.080 * mo_fbm1(t * 0.113, 2, 47.0) + 0.46 * st.turn;
    float tip  = 1.2708 + 0.050 * sin(t * 0.087);

    // The cloud is a little larger while it is dispersed and contracts as it
    // gathers -- nine per cent, which nobody sees as a size change and everybody
    // reads as a drawing-in.
    float R = MO_R * (1.0 + 0.085 * law.z);
    return mo_orb(sp, mo_frame(spin, tip), R, position, size, pixelScale,
                  inkColor, toneColor, hueShift, depth, glow, 0.34);
}

// MARK: - 6. Stir

// STIR. The sphere thinking with its hands.
//
// Dots lifted out of their seats, carried a little way, and set back down.
// Mechanically it is gather's fold at a tenth of the amplitude, driven by the
// flourish clock instead of by an arc -- which sounds like the same species
// twice and is not, because what a motion MEANS is set by its scale and its
// timing far more than by its formula. Gather's fold is an event that happens
// once and resolves; this one happens every four to nine seconds, forever, and
// never resolves into anything. One is an answer arriving. This is fidgeting.
//
// SEATED AND AIRBORNE. A dot in the air is dimmer and smaller than a dot in its
// seat, and that is the whole shading idea: without it the jostle is a wobble,
// and with it the settle is legible as a settle -- things landing. Each dot
// takes its own share of the jostle from its index hash, so they do not all lift
// and land together like a rehearsed chorus.
//
// `settle` shapes the envelope rather than the amplitude. High settle raises the
// flourish envelope to a higher power, which makes the jostle a sharp flick with
// a long quiet after it; low settle spreads the same energy into a lazy roll.
// Both are the same gesture and they are unmistakably different hands.
//
// THE FLOOR at 0.16 is the permanent tremor. Between gestures the lattice is
// still very slightly unsettled, because a sphere whose dots are perfectly
// seated for six seconds at a time is a diagram waiting for its next animation.
//
// RESPONDING STOPS THE FIDGETING, which is the one place in this pack where
// drive makes something quieter. A hand that has decided what it is doing stops
// drumming its fingers.
[[ stitchable ]] half4 mo_stir(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float t = time * max(speed, 0.0);
    MOState st = mo_state(stateIndex, stateTau);
    float4 fl = mo_flourish(t, 58.0);

    float jitter = clamp(c0, 0.0, 1.0);
    float settle = clamp(c1, 0.0, 1.0);

    float env = pow(fl.x, mix(0.75, 2.20, settle));

    MOSpec sp;
    sp.kind = 5;
    sp.n    = mo_count(size, formScale);
    sp.rad  = mo_radius(sp.n, c2);
    sp.accent = c3;
    sp.back = 0.72;
    sp.key  = 1.0;
    sp.k0 = jitter; sp.k1 = settle;
    sp.a0 = (0.16 + 0.84 * env) * (1.0 - 0.90 * st.accord) * (1.0 - 0.35 * st.drive);
    sp.a1 = 0.0;
    sp.a2 = t * 0.185 + 0.62 * fl.x;          // the field the jostle is read in
    sp.a3 = 0.0;
    sp.vec = float3(0.0, 0.0, 1.0);
    sp.t = t;
    sp.crest = st.crest; sp.wave = st.wave; sp.accord = st.accord;
    sp.settled = st.settled; sp.drive = st.drive;

    float spin = t * 0.35 + 0.095 * mo_fbm1(t * 0.127, 2, 58.0) + 0.50 * st.turn;
    float tip  = 1.2708 + 0.065 * sin(t * 0.095 + 1.4);

    return mo_orb(sp, mo_frame(spin, tip), MO_R, position, size, pixelScale,
                  inkColor, toneColor, hueShift, depth, glow, 0.32);
}

// MARK: - 7. Daybreak

// DAYBREAK. Dawn crossing a small planet.
//
// This is the one species that does not wear the pack's fixed key light, and it
// is because here the light IS the species. A sun direction circles the ball, so
// the terminator sweeps its face and TIME ENTERS WHERE A COORDINATE IS READ --
// a direction being rotated, not a brightness being turned up. That is the
// difference between a planet and a lamp on a dimmer, and it is the house rule
// this species exists to demonstrate on a figure that has countable parts.
//
// THE SUN'S ORBIT IS TILTED so it never passes fully behind the ball. A true
// circular orbit would leave the visible face almost entirely dark for half of
// every cycle, which on a planet is correct and in a chat UI reads as an
// indicator that has stopped. Tilted, the terminator crosses the face and off
// the limb and comes back, and the picture is never dark.
//
// THE DAWN LINE is the figure. Dots right at the terminator are the brightest
// thing in the frame -- which is true of a real sunrise seen from orbit, where
// the low sun rakes across everything at once -- and it gives this species a
// nameable silhouette: a bright arc crossing a dim ball, legible at 20 pt where
// a smooth day-night gradient would be one grey smudge.
//
// THE NIGHT SIDE floors at 0.30 rather than going out. A planet's night side is
// not empty, and more to the point, the lattice has to survive the sweep: dots
// that vanish behind the terminator take the object with them.
//
// `softness` is how wide the terminator is, which is really how much atmosphere
// the little planet has. THE GESTURE is a flare along the dawn line.
[[ stitchable ]] half4 mo_daybreak(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float t = time * max(speed, 0.0);
    MOState st = mo_state(stateIndex, stateTau);
    float4 fl = mo_flourish(t, 66.0);

    float sweep    = clamp(c0, 0.0, 1.0);
    float softness = clamp(c1, 0.0, 1.0);

    float rate = 0.15 + 0.26 * sweep;
    // RESPONDING drives the sun round the ball faster, added as an integrated
    // turn so the day does not jump to a new hour when the state changes.
    float sa = t * rate + rate * 1.25 * st.turn;

    MOSpec sp;
    sp.kind = 6;
    sp.n    = mo_count(size, formScale);
    sp.rad  = mo_radius(sp.n, c2);
    sp.accent = c3;
    sp.back = 0.58;
    // A quarter of the fixed key survives, purely so the ball still has a little
    // modelling when the sun is edge on. The sun does the rest.
    sp.key  = 0.28;
    sp.k0 = sweep; sp.k1 = softness;
    sp.a0 = 0.55 + 0.95 * fl.x;                       // the flare along the line
    sp.a1 = 0.0; sp.a2 = 0.0;
    // The terminator's width, and accord floods it: at the top of a success the
    // terminator is wider than the planet and the whole lattice is in daylight
    // at once, which is this family's arrival said in this species' own physics.
    sp.a3 = (0.10 + 0.30 * softness) * (1.0 + 3.4 * st.accord);
    sp.vec = normalize(float3(cos(sa) * 0.94, -0.32, 0.34 + 0.60 * sin(sa)));
    sp.t = t;
    sp.crest = st.crest; sp.wave = st.wave; sp.accord = st.accord;
    sp.settled = st.settled; sp.drive = st.drive;

    // The planet turns under its own sun, and slowly: two motions at close rates
    // would beat against each other and the sweep would look like it was
    // hunting. Well apart, they read as a day and a rotation.
    float spin = t * 0.24 + 0.070 * mo_fbm1(t * 0.101, 2, 66.0) + 0.40 * st.turn;
    float tip  = 1.2708 + 0.045 * sin(t * 0.067);

    return mo_orb(sp, mo_frame(spin, tip), MO_R, position, size, pixelScale,
                  inkColor, toneColor, hueShift, depth, glow, 0.35);
}

// MARK: - 8. Skein

// SKEIN. Dots strung along a winding thread that wraps the ball.
//
// The curve is longitude minus a multiple of latitude, which is the path a
// thread takes when you wind it round something: a spherical spiral, closing on
// itself at the poles, with the winding number saying how many times it goes
// round on the way. The dots near it are the strung ones and the rest of the
// lattice is the ball it is wound on, dim but present -- because a thread with
// nothing to wrap is a squiggle.
//
// THE WIDTH IS MEASURED PROPERLY, and this is the number that makes it read as a
// thread rather than as a lens artefact. The distance to the curve is the phase
// error DIVIDED BY the phase gradient. Without that division the band would be
// measured in radians of longitude, and a radian of longitude near a pole is
// almost no distance at all, so the thread would balloon out into two enormous
// caps. With it the thread is the same width everywhere, which is what a thread
// is.
//
// THE BEAD is a packet of light running the winding from pole to pole, and it is
// what stops this being a decoration: something is TRAVELLING, so the thread has
// a direction and a length, and the eye follows it round the back of the ball
// and waits for it to come out the other side. `trail` is how long the bead is,
// from a tight spark to a long glowing stretch of thread.
//
// WOUND AND UNWOUND. The winding number itself breathes by about a fifth over
// half a minute, so the spiral tightens and loosens and the thread appears to
// slide along its own length without any point of it ever moving sideways. That
// is the honest way to animate a winding: change the winding, not the position.
[[ stitchable ]] half4 mo_skein(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau
) {
    float t = time * max(speed, 0.0);
    MOState st = mo_state(stateIndex, stateTau);
    float4 fl = mo_flourish(t, 79.0);

    float winding = clamp(c0, 0.0, 1.0);
    float trail   = clamp(c1, 0.0, 1.0);

    float rate = 0.28 + 0.40 * trail;

    MOSpec sp;
    sp.kind = 7;
    sp.n    = mo_count(size, formScale);
    sp.rad  = mo_radius(sp.n, c2);
    sp.accent = c3;
    sp.back = 0.70;
    sp.key  = 1.0;
    sp.k0 = winding; sp.k1 = trail;
    // Three to nine turns pole to pole, breathing by a fifth: wound and unwound.
    sp.a0 = (3.0 + 6.0 * winding) * (1.0 + 0.20 * sin(t * 0.128));
    // The thread's own crawl, with RESPONDING added as an integrated turn.
    // THE GESTURE lives here too: for a couple of seconds the thread is pulled
    // and runs a lap faster than it has any business running.
    sp.a1 = t * rate + rate * 1.30 * st.turn + 2.60 * fl.x;
    // The bead, sweeping past both poles so it always leaves and always returns.
    sp.a2 = 1.92 * sin(t * 0.117 + 1.30);
    // The thread's half-width in radians, which is about one dot across at the
    // default lattice. Accord opens it past the radius of the ball, so at the
    // top of a success every dot in the lattice is on the thread at once.
    sp.a3 = (0.095 + 0.070 * (1.0 - trail)) * (1.0 + 11.0 * st.accord);
    sp.vec = float3(0.0, 0.0, 1.0);
    sp.t = t;
    sp.crest = st.crest; sp.wave = st.wave; sp.accord = st.accord;
    sp.settled = st.settled; sp.drive = st.drive;

    float spin = t * 0.31 + 0.085 * mo_fbm1(t * 0.119, 2, 79.0) + 0.46 * st.turn;
    float tip  = 1.2708 + 0.055 * sin(t * 0.073 + 0.4);

    return mo_orb(sp, mo_frame(spin, tip), MO_R, position, size, pixelScale,
                  inkColor, toneColor, hueShift, depth, glow, 0.34);
}
