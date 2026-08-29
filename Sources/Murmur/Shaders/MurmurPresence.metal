// The Presence pack. Eight indicators built the other way round from every other
// family in Murmur: not a material that was later given a state machine, but
// eight presences designed FOR the two live signals the host feeds them on every
// frame. `level` is the person's voice. `activity` is the cadence of typing, or
// of tokens arriving. A presence that ignores its person is decoration, and this
// is the family that exists so Murmur is not decoration.
//
//   mq_halo      a thin luminous ring tilting like a coin's edge. VOICE TRAVELS
//                ITS CIRCUMFERENCE as a wave -- a smooth ripple of brightness and
//                radial displacement running around the ring. Never bars.
//   mq_nucleus   a steady bright core inside a shell of circulating mist. VOICE
//                SWELLS THE SHELL, thicker and brighter; success collapses the
//                shell into the core with the flash.
//   mq_iris      an aperture of soft light petals. VOICE OPENS IT; silence eases
//                it shut to a slit glow; cadence puts a tremble in the tips.
//   mq_filament  one continuous thread of light. CADENCE TIES IT INTO A LIVELIER
//                KNOT, responding pulls it taut, at rest it coils, and voice runs
//                along its length like current in a wire.
//   mq_flare     a soft solar disc whose limb sprouts short organic licks with
//                VOICE. A voice meter that reads as a small sun. Never an EQ.
//   mq_braid     two strands orbiting a common centre: the conversation itself.
//                CADENCE TIGHTENS THE TWIST, responding braids them close, idle
//                lets them drift, and voice shifts the glow between the two.
//   mq_mote      the minimal presence: one soft light wandering a small closed
//                path. CADENCE MAKES IT LEAN AND QUICKEN toward its leading edge;
//                voice stretches it along its motion. Designed at 18 pt first.
//   mq_ripple    a still liquid disc, face-on, where input lands. EACH IMPULSE OF
//                CADENCE DROPS ONE SOFT RING that propagates out and fades; voice
//                raises a standing tremble across the whole surface.
//
// REACTIVE-FIRST, AND WHAT THAT MEANT IN PRACTICE. The rule that shaped every one
// of these was: name the species' signature response before writing a line of its
// body, then build the body so that response is its most natural motion rather
// than something added on top. The halo is a ring because a ring is the one shape
// a wave can travel forever without arriving anywhere. The ripple is face-on and
// still because a still surface is the only surface an impulse can visibly land
// on. The mote is nearly nothing because at 18 pt inside a text field, nearly
// nothing is all there is room for. A generic lift -- brighter when loud, faster
// when busy -- was available for all eight and is what these are instead of.
//
// THE SIGNAL IS A GUEST, NOT A POWER SUPPLY. Every species is complete, alive and
// worth looking at at level = 0 and activity = 0, because that is the state a
// gallery screenshot catches and the state a silent app sits in for hours. The
// live signals RIDE ON a presence that already has its own quiet life: the halo's
// wave still travels at a tenth of its amplitude, the flare still simmers small
// tongues at its limb, the ripple still drops a ring every five or six seconds on
// its own. Nothing here switches off when nobody is talking. Read that as the
// mirror of `glow`'s rule in the rail: a dial that can turn a presence off is a
// bug and not a dial.
//
// SIZE-FIRST. These mount at three sizes and the middle one is not the design
// target: an 18 pt inline field, a 46 pt chip, a 120 pt+ voice stage. So `size`
// is a real input here and not a normaliser. mq_small() turns it into one number
// and every species spends it the same way -- STRUCTURE COUNTS DOWN, STROKES
// THICKEN. At 18 pt the iris drops from nine petals to five, the halo's wave
// loses its third and fifth harmonics and its stroke nearly triples in relative
// width, the braid loses a crossing, the filament unwinds two turns, the mote
// grows by half and drops its granulation, the ripple widens its ring crests and
// gives up its finest tremble mode. What survives at 18 pt is ONE bold gesture
// per species. At 120 pt and up all of it comes back, and the fine structure that
// was suppressed -- granulation, filigree in the mist, the third wave harmonic --
// is what makes the large mount worth watching. A stroke that is 0.02 uv wide is
// five pixels at 120 pt and two thirds of a pixel at 18 pt, which is the whole
// argument in one number.
//
// THE STATE INDICES MOVED, and this file is the first written against the new
// map: 0 idle, 1 listening, 2 thinking, 3 RESPONDING, 4 SUCCESS, 5 error. The
// older packs branch on 2 and 3 for the same two states. mq_state() below is
// written to the new numbers; if you are reading this next to MurmurSignal.metal
// and the comparison looks wrong, that is why.
//
// LISTENING IS THIS FAMILY'S HOME STATE. It is the state a voice presence spends
// its most interesting seconds in, and it is where `level` does its deepest work:
// mq_live() gives voice its full weight in listening and a bit over half of it
// everywhere else, because a person talking over a thinking assistant should
// still be acknowledged, just not as though nothing else were happening.
//
// SUCCESS COMPLETES THE PRESENCE'S OWN PATTERN, AND IT TRAVELS. Every family in
// Murmur brightens its own structure for a breath on success rather than washing
// white over it; this family adds that the surge has somewhere to GO. mq_state
// returns a `sweep` that runs 0 to 1 once across the success window, and each
// species spends it on its own geometry: a glint laps the halo's ring, a pulse
// runs the filament's whole length and closes the circuit, a bright ring races
// out through the iris's blades and the flare's licks, the mote's hidden path
// lights up and a flash runs it once round, the braid's two strands merge into
// one cord as light travels it, the nucleus's shell rushes inward and is
// swallowed by the core, and the ripple drops one last ring at dead centre that
// reaches the rim. Arrival with a direction reads as arrival; a flash in place
// reads as a flicker.
//
// THE CIRCLE. The view clips to a Circle at length(uv) = 0.5 and no species is
// allowed to lean on that: everything is ink again by a uv radius of about 0.45,
// which is what mq_containment is for. The flare's tongues are the one place this
// took a hard cap rather than a gentle falloff -- a flame at full voice with the
// prominence gesture on top would otherwise reach the rim and get sliced, and a
// sliced flame is the most obvious tell in the file.
//
// COPIED HELPERS. Cross-file Metal linkage is not guaranteed, so the kit is
// copied out of FieldLab.metal and FieldPackPour.metal (by way of
// MurmurSignal.metal, which is this pack's conventions exemplar) VERBATIM under
// an mq_ prefix. Copied, unchanged except for the name:
//
//   mq_hash, mq_grad3, mq_noise3, MQ_ROT, mq_fbm3,
//   mq_hash1, mq_vnoise1, mq_fbm1,
//   mq_srgb_to_linear, mq_linear_to_srgb, mq_linear_to_oklab,
//   mq_oklab_to_linear, mq_lch, MQPalette, mq_palette, mq_shade,
//   mq_out, mq_knee, mq_tier, mq_lit, mq_aa, mq_containment, mq_finish,
//   mq_ball (ms_orb), mq_spin
//
// Their comments come with them: the reasoning is the part worth carrying.
//
// WHAT IS DELIBERATELY NOT COPIED. mq_settle_law, because not one species in this
// family honours `epoch`: these are presences that are always on, not arcs that
// arrive and settle, and the eight roster entries are all arc-free. Copying a
// settle law nothing calls would leave dead code behind a prefix. The
// derivative-carrying noise pair is not copied either -- the two species that
// light a surface by its slope, ripple and halo, both build that surface from
// closed-form profiles whose derivatives are exact and free.
//
// WHAT IS NEW HERE, and it is three things: mq_live, which conditions the two
// live signals once so all eight read them the same way; mq_small, the size
// dial described above; and mq_ring_noise, because half this family needs noise
// that varies AROUND a circle, and a one-dimensional fBm in the polar angle
// leaves a seam at the wrap that reads as a scar down the ring.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - The copied kit
//
// Everything in this section is FieldLab.metal's, FieldPackPour.metal's or
// MurmurSignal.metal's, verbatim, renamed.

/// An integer avalanche. Lattice coordinates in, well-mixed bits out. A sine
/// hash was the other option and it drifts into visible repeats once the domain
/// gets large, which the long previews here would find.
static inline uint mq_hash(uint3 v) {
    uint h = v.x * 1597334673u ^ v.y * 3812015801u ^ v.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u;
    h ^= h >> 13; h *= 3266489917u;
    h ^= h >> 16;
    return h;
}

/// A unit vector distributed uniformly on the sphere, from one lattice cell.
/// Uniform matters: gradients bunched near the poles put a grain in the field
/// that reads as a weave once the octaves stack.
static inline float3 mq_grad3(int3 c) {
    uint h = mq_hash(uint3(c + 4096));
    float z = fma(float(h & 0xFFFFu), 2.0 / 65535.0, -1.0);
    float a = float((h >> 16) & 0xFFFFu) * (6.28318530718 / 65536.0);
    float r = sqrt(max(0.0, 1.0 - z * z));
    return float3(r * cos(a), r * sin(a), z);
}

/// The value alone, for the places that never ask what the slope is.
static float mq_noise3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    int3 c = int3(i);

    float va = dot(mq_grad3(c + int3(0, 0, 0)), f - float3(0.0, 0.0, 0.0));
    float vb = dot(mq_grad3(c + int3(1, 0, 0)), f - float3(1.0, 0.0, 0.0));
    float vc = dot(mq_grad3(c + int3(0, 1, 0)), f - float3(0.0, 1.0, 0.0));
    float vd = dot(mq_grad3(c + int3(1, 1, 0)), f - float3(1.0, 1.0, 0.0));
    float ve = dot(mq_grad3(c + int3(0, 0, 1)), f - float3(0.0, 0.0, 1.0));
    float vf = dot(mq_grad3(c + int3(1, 0, 1)), f - float3(1.0, 0.0, 1.0));
    float vg = dot(mq_grad3(c + int3(0, 1, 1)), f - float3(0.0, 1.0, 1.0));
    float vh = dot(mq_grad3(c + int3(1, 1, 1)), f - float3(1.0, 1.0, 1.0));

    return mix(mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y),
               mix(mix(ve, vf, u.x), mix(vg, vh, u.x), u.y), u.z);
}

/// The per-octave rotation. Orthonormal, so its transpose is its inverse.
/// Without it every octave stacks on the same lattice axes and the field grows a
/// visible plaid.
constant float3x3 MQ_ROT = float3x3(float3( 0.00,  0.80,  0.60),
                                    float3(-0.80,  0.36, -0.48),
                                    float3(-0.60, -0.48,  0.64));

static float mq_fbm3(float3 p, int octaves, float lacunarity, float gain) {
    float3 q = p;
    float amp = 0.5;
    float value = 0.0;
    for (int i = 0; i < octaves; i++) {
        value += amp * mq_noise3(q);
        amp *= gain;
        q = lacunarity * (MQ_ROT * q);
    }
    return value;
}

static inline float mq_hash1(float cell, float lane) {
    return float(mq_hash(uint3(uint(int(cell) + 32768), uint(int(lane) + 32768), 0x9E3779B9u)) >> 8)
         * (1.0 / 16777216.0);
}

/// Value noise on a line, quintic-interpolated so its slope is continuous and
/// a silhouette built on it has no corners the eye can find.
static inline float mq_vnoise1(float x, float lane) {
    float i = floor(x), f = x - i;
    float u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(mq_hash1(i, lane), mq_hash1(i + 1.0, lane), u) * 2.0 - 1.0;
}

/// fBm on a line. Amplitude halves, frequency a hair past doubles (2.03, so no
/// two octaves ever land on the same cell wall). Range is about plus or minus
/// one for four octaves.
static float mq_fbm1(float x, int octaves, float lane) {
    float v = 0.0, amp = 0.5, f = 1.0;
    for (int i = 0; i < octaves; i++) {
        v += amp * mq_vnoise1(x * f, lane + float(i) * 37.0);
        amp *= 0.5;
        f *= 2.03;
    }
    return v;
}

static inline float3 mq_srgb_to_linear(float3 c) {
    c = max(c, 0.0);
    return select(c * (1.0 / 12.92), pow((c + 0.055) * (1.0 / 1.055), 2.4), c > 0.04045);
}

static inline float3 mq_linear_to_srgb(float3 c) {
    c = max(c, 0.0);
    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c > 0.0031308);
}

static inline float3 mq_linear_to_oklab(float3 c) {
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

static inline float3 mq_oklab_to_linear(float3 lab) {
    float l_ = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
    float m_ = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
    float s_ = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
    float l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    return float3( 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                  -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                  -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

/// Lightness, chroma, hue back into OKLAB's rectangular form.
static inline float3 mq_lch(float L, float C, float h) {
    return float3(L, C * cos(h), C * sin(h));
}

/// Four OKLAB stops built from one anchor: the tone the indicator wears.
/// Ordered dark to bright, and never more than one hue family wide.
struct MQPalette { float3 s0, s1, s2, s3; };

/// s0 is the ink the whole app sits on, so a field at zero dissolves into the
/// screen with no seam. s1 is a deep shadow that KEEPS the tone's hue at half
/// its chroma, which is what stops the dark end going grey. s2 is the tone. s3
/// is a pale specular a few degrees warmer, because light that has passed
/// through anything comes out warmer than the thing it lit.
/// `depth` opens the range from both ends without letting the hue wander.
static MQPalette mq_palette(half4 inkColor, half4 toneColor, float hueShift, float depth) {
    float3 ink = mq_linear_to_oklab(mq_srgb_to_linear(float3(inkColor.rgb)));
    float3 tone = mq_linear_to_oklab(mq_srgb_to_linear(float3(toneColor.rgb)));

    float L = tone.x;
    float C = length(tone.yz);
    float h = atan2(tone.z, tone.y) + hueShift;
    float d = clamp(depth, 0.30, 2.00);

    // The shadow shifts WARM as it darkens, roughly twenty degrees of hue
    // toward ember, and keeps most of its chroma rather than draining to grey.
    // Both of those are the difference between a deep amber and mud: a straight
    // desaturating fall from gold to ink passes through olive, and olive is what
    // the first cut of every one of these fields looked like.
    MQPalette p;
    p.s0 = ink;
    p.s1 = mq_lch(mix(ink.x, L, 0.30 / d), C * (0.52 + 0.10 * d), h - 0.35);
    p.s2 = mq_lch(L, C, h);
    p.s3 = mq_lch(min(L * (1.20 + 0.12 * d), 0.93), C * 0.55, h + 0.10);
    return p;
}

/// Walk the family. Three segments, each eased so its ends are flat, which
/// makes the joins C1: no kink shows up as a contour line in a smooth field.
/// Returns LINEAR light; mq_out does the encoding.
static float3 mq_shade(MQPalette p, float t) {
    t = clamp(t, 0.0, 1.0);
    float3 lab;
    if (t < 0.40) {
        lab = mix(p.s0, p.s1, smoothstep(0.0, 1.0, t * 2.5));
    } else if (t < 0.78) {
        lab = mix(p.s1, p.s2, smoothstep(0.0, 1.0, (t - 0.40) * (1.0 / 0.38)));
    } else {
        lab = mix(p.s2, p.s3, smoothstep(0.0, 1.0, (t - 0.78) * (1.0 / 0.22)));
    }
    return mq_oklab_to_linear(lab);
}

/// The last thing every field does. One code value of triangular-PDF
/// interleaved-gradient dither, in the encoded space where the quantization
/// actually happens. Triangular rather than uniform because uniform dither
/// leaves a faint texture of its own in flat areas; triangular does not.
static inline half4 mq_out(float3 linearRGB, float2 pixel) {
    float3 c = mq_linear_to_srgb(linearRGB);
    float n = fract(52.9829189 * fract(dot(pixel, float2(0.06711056, 0.00583715))));
    float tri = n < 0.5 ? (sqrt(2.0 * n) - 1.0) : (1.0 - sqrt(max(0.0, 2.0 - 2.0 * n)));
    c += tri * (1.0 / 255.0);
    return half4(half3(saturate(c)), 1.0h);
}

/// A soft knee, the same one the route curtain uses. Below the knee nothing
/// changes; above it the tail compresses asymptotically instead of clipping,
/// which is what stops a bright field turning into flat white paper.
static inline float mq_knee(float x, float knee) {
    return x < knee ? x : knee + (1.0 - knee) * (1.0 - exp(-(x - knee) / max(1.0 - knee, 1e-3)));
}

/// THE CONTAINMENT. fl_edge's job, done for a circle instead of a screen.
///
/// The view clips these indicators to a Circle at length(uv) = 0.5, and a clip
/// is a hard edge: any form still carrying light when it arrives is sliced, and
/// a sliced organic form is the most obvious tell that a field was built for a
/// rectangle. So every species dissolves to PURE INK before the rim, which also
/// gives the indicator a soft silhouette of its own and means it would read
/// correctly with no clip at all. The clip is a guarantee, not the design.
///
/// `reach` is where the fall begins, on the doubled radius (1.0 is the clip).
/// The 0.31 span puts full ink at reach + 0.31, so the callers' 0.58 to 0.62 all
/// land between a uv radius of 0.445 and 0.465: inside the clip with room to
/// spare, and wide enough that the falloff itself is never a visible ring.
static inline float mq_containment(float2 uv, float reach) {
    float r = length(uv) * 2.0;
    return 1.0 - smoothstep(reach, reach + 0.31, r);
}

/// THE VALUE HIERARCHY, as one curve.
///
/// Three tiers or it fails: ink ground, amber body, CREAM PEAKS. A cell whose
/// brightest pixel is rust is a cell nobody can parse, and these are small
/// objects in a chat UI rather than surfaces someone lives beside.
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
/// map this shallow shows up as a contour line in a smooth field.
///
/// What this asks of every species: normalise so the figure's SPINE reaches
/// about 1.0 while its body sits between 0.35 and 0.7.
static inline float mq_tier(float e) {
    float x = clamp(e, 0.0, 1.0);
    const float K = 0.78;
    float body = (x / K) * 0.72;
    float peak = 0.72 + ((x - K) / (1.0 - K)) * 0.28;
    return mix(body, peak, smoothstep(K - 0.10, K + 0.10, x));
}

/// THE ONE PLACE ENERGY BECOMES LIGHT. All eight species compute a density in
/// 0...1 and hand it here, which is most of what keeps the family reading as one
/// family: there is exactly one relationship between how much material is at a
/// pixel and how bright and how warm that pixel is, and no species invents its
/// own.
///
/// `glow` is the presence dial and it enters twice, both times where it cannot
/// lie: it scales the energy BEFORE the rail walk, so a lower setting walks less
/// far and therefore reads cooler and deeper rather than merely faded, and it
/// scales the emission on top. At glow = 1 the first term is the identity. At
/// glow = 0 a third of the energy survives, because an indicator that can be
/// switched off by a dial is a bug and not a dial.
///
/// The knee before the rail walk, and not a clamp, because a clamp is where
/// these species would go wrong in the same way: several of them build an energy
/// that can pass 1 in their bright places, and clamping turns those places into
/// FLAT plateaus of identical colour with a visible contour around them. The
/// knee compresses the same overshoot asymptotically, so a wave crest or the
/// core of a mote keeps its shape instead of becoming a patch.
static inline float3 mq_lit(MQPalette pal, float e, float glow,
                            float base, float span, float emis) {
    float G = max(glow, 0.0);
    float en = clamp(mq_knee(max(e, 0.0) * (0.35 + 0.65 * G), 0.92), 0.0, 1.0);
    float tRail = clamp(base + span * mq_tier(en), 0.0, 1.0);
    float3 col = mq_shade(pal, tRail);
    // Emission is gated to the specular, not to the tone: the rail reaches the
    // top routinely, and emission from the whole amber body would put the ground
    // back up and flatten the very hierarchy mq_tier just built.
    return col * (1.0 + emis * G * smoothstep(0.72, 1.0, tRail));
}

/// THE ANTI-ALIAS GATE. Where a species puts full amplitude on a CHOSEN
/// frequency -- the ripple's finest standing mode, the flare's granulation --
/// that frequency has a floor: below about two pixels a cycle it stops being a
/// form and becomes moire, which at 18 pt with the form scale wound down is a
/// real setting and not a theoretical one.
///
/// `cycles` is the structure's wavenumber in radians per uv unit, and the frame
/// gives the rest: one uv unit is min(size) points, which is min(size) *
/// pixelScale pixels. The gate returns 1 while the structure is comfortably
/// resolved and eases its CONTRIBUTION to nothing as it approaches a third of a
/// cycle per pixel, so structure that can no longer be drawn honestly becomes
/// its own soft average instead of a sparkle.
static inline float mq_aa(float cycles, float2 size, float pixelScale) {
    float px = max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0);
    float perPixel = max(cycles, 0.0) / (6.2831853 * px);
    return 1.0 - smoothstep(0.16, 0.36, perPixel);
}

/// THE BALL. Four things sell a sphere and this returns all four.
///
///   p     THE WRAP COORDINATE. Every point inside the limb maps to a point on
///         the unit sphere, so a material sampled at `p` is painted ON the ball
///         rather than behind it: features foreshorten toward the limb by
///         themselves, because that is what the mapping does.
///   z     the height of the surface, one at the centre and zero at the limb.
///   limb  depth dimming. Material at the edge is seen at a grazing angle and
///         through more of the body, so it falls away.
///   lit   one fixed key, up and left, the way a body catches a room. Gentle:
///         at 0.42 the dark side is still material and not a hole.
///
/// The limb is SOFT. A hard circle is a drawn disc, and nothing in this family
/// has a hard edge; two per cent of feather reads as a body rather than a
/// cut-out.
struct MQBall {
    float2 s;     // in-plane, normalised so the limb sits at |s| = 1
    float  z;     // the sphere's height here
    float3 p;     // the point on the unit sphere: where the material lives
    float  m;     // membership, soft at the limb
    float  limb;  // depth dimming toward the edge
    float  lit;   // the key light
};

static MQBall mq_ball(float2 uv, float R) {
    MQBall o;
    o.s = uv / max(R, 1e-3);
    float r2 = dot(o.s, o.s);
    o.z = sqrt(max(1.0 - min(r2, 1.0), 0.0));
    o.p = float3(o.s, o.z);
    o.m = 1.0 - smoothstep(0.93, 1.02, sqrt(r2));
    o.limb = pow(clamp(o.z, 0.0, 1.0), 0.55);
    o.lit = 0.42 + 0.58 * clamp(dot(o.p, float3(-0.40, 0.47, 0.79)), 0.0, 1.0);
    return o;
}

/// Turn the ball. One rotation about the vertical, which is the presence turning
/// to face you, and a tilt, so the pole never sits still long enough to become a
/// landmark the eye can lock onto.
static inline float3 mq_spin(float3 p, float ay, float ax) {
    float ca = cos(ay), sa = sin(ay);
    float3 q = float3(ca * p.x + sa * p.z, p.y, -sa * p.x + ca * p.z);
    float cb = cos(ax), sb = sin(ax);
    return float3(q.x, cb * q.y - sb * q.z, sb * q.y + cb * q.z);
}

/// The house finish, shared: ink underneath, the field composited into it by the
/// containment, the same knee the route curtain puts on its surface colour, and
/// the dither last. Every species ends on this line.
static inline half4 mq_finish(float3 field, float3 inkLin, float containment,
                              float2 position, float pixelScale) {
    float3 rgb = mix(inkLin, field, containment);
    rgb = float3(mq_knee(rgb.r, 0.90), mq_knee(rgb.g, 0.90), mq_knee(rgb.b, 0.90));
    return mq_out(rgb, position * pixelScale);
}

// MARK: - The pack's own tools
//
// Three things this family needs that no other pack did: a conditioner for the
// live signals, a size dial, and noise that closes around a circle.

/// THE LIVE SIGNALS, CONDITIONED ONCE.
///
/// The host hands two raw scalars and all eight species read them through here,
/// so "loud" and "busy" mean the same thing across the family and a person
/// switching styles in the lab is comparing designs rather than gain staging.
///
/// THE CURVE. A microphone level that is mapped linearly spends most of its
/// travel in the top quarter and reads as a gate: nothing, nothing, nothing,
/// everything. Ordinary speech sits low and its interesting structure is down
/// there, so voice is raised to 0.65 -- a little stronger than a square root --
/// which puts a normal speaking level near two thirds of the response and leaves
/// real headroom above it for emphasis. Cadence gets a gentler 0.85: typing rate
/// arrives already smoothed by the host and does not need the same expansion.
///
/// THE STATE WEIGHTS. Voice is at full strength in LISTENING, which is this
/// family's home state and the state these designs exist for, and at 0.55
/// elsewhere -- a person talking over a thinking assistant is still worth
/// acknowledging, just not as though nothing else were going on. Cadence is at
/// full strength in THINKING and RESPONDING, where a token stream is the thing
/// actually happening, and at 0.6 elsewhere.
///
/// Both are clamped, both are zero-safe, and every species is designed to be
/// complete when both are zero. See the header: the signal is a guest.
struct MQLive {
    float voice;   // level, shaped and state-weighted
    float pace;    // activity, shaped and state-weighted
};

static MQLive mq_live(float level, float activity, float stateIndex) {
    MQLive o;
    float L = clamp(level, 0.0, 1.0);
    float A = clamp(activity, 0.0, 1.0);
    float listening = (stateIndex > 0.5 && stateIndex < 1.5) ? 1.0 : 0.0;
    float working   = (stateIndex > 1.5 && stateIndex < 3.5) ? 1.0 : 0.0;
    o.voice = pow(L, 0.65) * mix(0.55, 1.00, listening);
    o.pace  = pow(A, 0.85) * mix(0.60, 1.00, working);
    return o;
}

/// THE SIZE DIAL. One number, 1 at 18 pt and 0 at 120 pt and above, and every
/// species spends it the same way: structure counts down, strokes thicken.
///
/// The midpoint sits at about 46 pt, the chip mount, so the chip lands two
/// thirds of the way toward the small treatment -- which is right, because a 46
/// pt chip is a small object that happens to be bigger than the smallest one.
static inline float mq_small(float2 size) {
    return 1.0 - smoothstep(16.0, 88.0, max(min(size.x, size.y), 1.0));
}

/// THE COUNT DIAL. Some structure cannot be crossfaded because its count has to
/// be an INTEGER or the form fails to close around the circle: the iris's petals,
/// the braid's crossings, the filament's turns. Those switch, and they switch
/// below about 36 pt, well under the chip. `size` is uniform across a draw, so
/// the branch is free and no pixel ever disagrees with its neighbour.
static inline float mq_tiny(float2 size) {
    return 1.0 - smoothstep(20.0, 38.0, max(min(size.x, size.y), 1.0));
}

/// ANGULAR NOISE THAT CLOSES.
///
/// Half this family needs a field that varies AROUND a circle -- the halo's
/// shimmer, the flare's licks, the iris's tremble. Reading a one-dimensional fBm
/// in the polar angle is the obvious way and it is wrong: the domain wraps at
/// plus and minus pi and the noise does not, so there is a discontinuity down one
/// radius of every ring. It reads as a scar and no amount of amplitude tuning
/// hides it.
///
/// So the noise is read ON the circle instead: a ring of radius `freq` in the
/// three-dimensional lattice, which by construction has no seam because it has no
/// end. The feature count around the ring is about 2 pi freq, so freq 1.0 gives
/// six or seven features and freq 0.5 gives three -- which is exactly the dial
/// the small mounts want. `drift` walks the third axis so the pattern evolves in
/// place; subtracting a travel term from `ang` slides the whole pattern around
/// the ring instead.
static inline float mq_ring_noise(float ang, float freq, float drift) {
    return mq_noise3(float3(cos(ang) * freq, sin(ang) * freq, drift));
}

/// THE STATE READ, shared by all eight species.
///
/// Two of the six states get an in-shader design; the rest are carried by the
/// per-state parameter sets the Swift layer interpolates, which is the right
/// division of labour -- a dial change is a dial change and does not belong in a
/// branch here.
///
/// SUCCESS (index 4) is this family's moment and it TRAVELS. `complete` is the
/// breath of arrival: in over about a third of a second, out over the rest of
/// 1.2, on a curve whose ends are flat so nothing snaps. `sweep` is the same
/// window read as a position, 0 to 1 over 0.95 s, and it is what each species
/// runs its flash ALONG: a lap of the halo, the length of the filament, the
/// radius of the iris, the mote's whole hidden path. `settled` is what is left
/// afterwards and holds for as long as the state does -- the presence a little
/// brighter and a little more resolved than it was.
///
/// The light in a success is NOT an overlay. Every species multiplies its own
/// energy by (1 + complete), which brightens exactly what is already there and
/// leaves the dark dark: the surge travels through the species' own structure
/// because it IS the species' own structure, scaled.
///
/// RESPONDING (index 3) is decisive drive: the presence stops casting about and
/// acquires a direction, continuously, for as long as the state holds. `drive`
/// ramps in over half a second so entering the state is a lean and not a jolt.
///
/// The indices are the new map -- 0 idle, 1 listening, 2 thinking, 3 responding,
/// 4 success, 5 error -- and NOT the one the older packs branch on.
struct MQState {
    float complete;   // success: the arrival, one breath
    float sweep;      // success: where the arrival has travelled to, 0...1
    float settled;    // success: what is left after it
    float drive;      // responding: directional urgency, held
};

static MQState mq_state(float stateIndex, float stateTau) {
    MQState o;
    o.complete = 0.0; o.sweep = 0.0; o.settled = 0.0; o.drive = 0.0;
    float tau = max(stateTau, 0.0);
    if (stateIndex > 3.5 && stateIndex < 4.5) {
        float a = clamp(tau / 1.20, 0.0, 1.0);
        o.complete = smoothstep(0.0, 0.30, a) * (1.0 - smoothstep(0.36, 1.0, a));
        o.settled  = smoothstep(0.30, 1.05, a);
        // The sweep is eased at both ends: a flash that starts at full speed and
        // stops dead is a wipe, and a wipe is a UI transition rather than an
        // arrival travelling through a material.
        o.sweep    = smoothstep(0.0, 1.0, clamp(tau / 0.95, 0.0, 1.0));
    } else if (stateIndex > 2.5 && stateIndex < 3.5) {
        o.drive = smoothstep(0.0, 0.55, tau);
    }
    return o;
}

/// THE FLOURISH CLOCK, and it is the pack's play mechanism.
///
/// Every species here performs ONE gesture: a thing the presence does now and
/// then and then lets go of. The clock says when, and the three rules it exists
/// to keep are all in its arithmetic.
///
/// APERIODIC, NEVER A METRONOME. Time is cut into 6.5 second slots and each slot
/// holds exactly one gesture, but WHERE in its slot the gesture falls is hashed
/// per slot. The interval between two onsets is therefore the slot length plus
/// the difference of two independent jitters -- about four to nine seconds, with
/// no two gaps the same and nothing for the eye to lock onto.
///
/// DETERMINISTIC. The slot index is floor(t / SLOT) and everything else is a
/// hash of it, so any t at all renders the correct frame: a screenshot rig, a
/// scrubbed slider and a resumed app all agree. There is no state between frames
/// anywhere in this pack and play does not get to be the exception.
///
/// NOTHING SNAPS. The envelope is sin^2(pi u), which is zero with zero slope at
/// both ends. It does not begin, it arrives; it does not stop, it finishes.
///
/// Returns (envelope, progress, a per-gesture random, THE GESTURE'S DURATION).
/// The exemplar returns its slot index in the fourth slot and this pack returns
/// the duration instead, because the mote's lean has to be honest: its blob
/// leans into the direction it is actually travelling, the dart displaces it, and
/// a displacement's contribution to velocity cannot be computed without knowing
/// how long the displacement takes.
static float4 mq_flourish(float t, float lane) {
    const float SLOT = 6.5;
    float slot = floor(t / SLOT);
    float local = t - slot * SLOT;
    float start = 1.15 + 2.20 * mq_hash1(slot, lane);
    float dur   = 1.60 + 1.40 * mq_hash1(slot + 811.0, lane);
    float u = (local - start) / dur;
    float sn = sin(3.14159265 * clamp(u, 0.0, 1.0));
    float env = (u <= 0.0 || u >= 1.0) ? 0.0 : sn * sn;
    return float4(env, clamp(u, 0.0, 1.0), mq_hash1(slot + 1607.0, lane), dur);
}

// MARK: - 1. Halo

// HALO. A ring of light with a voice running around it.
//
// THE REACTIVE SIGNATURE: `level` TRAVELS THE CIRCUMFERENCE. This is the species
// that had to solve the hardest brief in the family, which is showing voice on a
// ring without drawing bars. Every voice visualisation reflex -- segments around
// a circle, spikes off a rim, a radial equaliser -- is a countable thing, and a
// countable thing is not this product. So the ring here is never sampled into
// pieces. It is a CONTINUOUS CURVE whose radius is displaced by a travelling wave
// and whose brightness rides the same wave, and the wave is a sum of three
// harmonics at 2, 3 and 5 cycles round the ring, each running at its own angular
// speed. Integer harmonics because only an integer closes; three of them because
// two look like a wobble and four start to look like teeth; incommensurate speeds
// because their sum then never repeats and the eye cannot find the loop.
//
// What a person sees: at silence a slow lazy undulation, and as they speak, a
// ripple running around the ring, brightening where the ring bulges outward. It
// is one continuous thing at every amplitude, which is the whole point.
//
// THE COIN. The ring is tilted in three dimensions and its lean precesses, so it
// is a body in space rather than a circle in a UI. The tilt never reaches flat --
// a flat ring is a progress spinner -- and never reaches edge-on, where the
// presence would vanish into a line. `activity` quickens the precession: a busy
// assistant turns its face faster.
//
// AT SMALL SIZE the coin flattens toward face-on and loses its third and fifth
// harmonics, because five lobes on a ring 35 points around is a texture rather
// than a gesture, and because a strongly foreshortened ellipse at 18 pt reads as
// a smudge. The stroke goes from 0.021 uv to 0.058 -- from three pixels at 120 pt
// to three pixels at 18 pt, which is the honest way to say "thicken it".
//
// THE FACE. A faint disc of amber air fills the ellipse. Without it a ring on ink
// is a wireframe; with it the coin has a body and the presence is an object.
[[ stitchable ]] half4 mq_halo(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float tiltK     = clamp(c0, 0.0, 1.0);   // how far the coin leans
    float thickK    = clamp(c1, 0.0, 1.0);   // the stroke
    float waviness  = clamp(c2, 0.0, 1.0);   // how much of the wave is structural
    float shimmerK  = clamp(c3, 0.0, 1.0);   // fine light along the rim

    MQState st = mq_state(stateIndex, stateTau);
    MQLive live = mq_live(level, activity, stateIndex);
    float small = mq_small(size);

    float4 fl = mq_flourish(t, 5.0);

    // THE TILT. Bounded well away from both failures, wobbling slowly so the
    // ellipse is never the same shape twice, and flattened at small size.
    float lean = mix(0.34, 0.88, tiltK) * mix(1.0, 0.45, small);
    float tilt = 0.22 + 0.72 * lean + 0.10 * lean * sin(t * 0.191)
               + fl.x * 0.16 * lean;                       // the gesture tips it
    float cosT = max(cos(tilt), 0.16);
    float sinT = sin(tilt);

    // PRECESSION: which way it leans, going round. Quickened by cadence and again
    // by responding, which is where the coin turns with intent.
    float prec = t * 0.155 * (1.0 + 1.30 * live.pace) * (1.0 + 1.10 * st.drive);
    float cp = cos(prec), sp = sin(prec);
    float2 q = float2(cp * uv.x + sp * uv.y, -sp * uv.x + cp * uv.y);

    // The ring, as an ellipse: semi-axes R across and R cos(tilt) down.
    float R = 0.290 * mix(1.0, 0.92, small);
    float a = R, b = R * cosT;
    float2 e = float2(q.x / a, q.y / b);
    float k = length(e);
    float phi = atan2(e.y, e.x);                 // the parameter around the ring

    // First-order distance to the ellipse. f = |e| - 1 is the implicit form and
    // dividing by the gradient's length turns it into a distance in uv, which is
    // what makes the stroke an even width all the way round instead of pinching
    // at the ends of the minor axis.
    //
    // The gradient is taken on the UNIT vector rather than on e itself, and that
    // is not a stylistic choice: both go to zero together at the centre of the
    // frame, and the ratio of two vanishing quantities under a guard evaluates to
    // zero, which would report the centre pixel as being ON the ring and light a
    // false dot in the middle of the coin. Normalising first makes the
    // denominator bounded between 1/a and 1/b everywhere, and the degenerate
    // centre falls out correctly as a distance of -a.
    float2 ehat = k > 1e-5 ? e / k : float2(1.0, 0.0);
    float2 gr = float2(ehat.x / a, ehat.y / b);
    float dist = (k - 1.0) / max(length(gr), 1e-4);

    // THE WAVE. Three integer harmonics, three speeds. At small size the upper
    // two are faded out and what is left is one long lobe travelling, which is
    // the same gesture said with fewer words.
    float hiHarm = mix(1.0, 0.22, small);
    float ws = 1.0 + 1.05 * live.pace + 0.85 * st.drive;
    float wu = 0.55 * sin(2.0 * phi - t * 0.75 * ws)
             + 0.32 * sin(3.0 * phi - t * 1.15 * ws + 1.7) * hiHarm
             + 0.20 * sin(5.0 * phi - t * 0.60 * ws + 4.1) * hiHarm;

    // The voice term. A tenth of the amplitude survives at silence, so the ring
    // is always breathing, and the rest is the person.
    float vA = 0.12 + 0.88 * live.voice;
    float disp = wu * vA * (0.028 + 0.052 * waviness) * mix(1.0, 0.75, small);
    float dRing = dist - disp;

    // THE STROKE, and the number that matters most in this file. 0.021 uv is
    // about three pixels at 120 pt; the small end is 0.058, which is about three
    // pixels at 18 pt. Same ring, same read, at both mounts.
    float th = mix(0.021, 0.032, thickK) * mix(1.0, 2.55, small);
    float core = exp(-(dRing * dRing) / (th * th));
    float bs = min(th * 3.1, 0.072);                 // capped so the tail cannot
    float bloom = exp(-(dRing * dRing) / (bs * bs)); // reach the clip at 18 pt

    // Brightness rides the same wave that displaced the ring: light bunches on
    // the crests. One term, so displacement and brightness can never disagree
    // and turn the ring into a string of beads.
    float crest = 1.0 + (0.35 + 0.95 * live.voice) * max(wu, 0.0);

    // The rim's own fine light, drifting round. Read on the circle so there is no
    // seam; drifting slowly against the wave so the two never lock.
    float sh = mq_ring_noise(phi - t * 0.21, 2.4 / S, t * 0.11);
    float shim = 1.0 - shimmerK * 0.42 + shimmerK * 0.84 * clamp(0.5 + 1.3 * sh, 0.0, 1.0);

    // Depth. The far half of a tilted ring is further away and dimmer; at
    // face-on the cue disappears by itself, because sin(tilt) is what carries it.
    float front = 0.64 + 0.36 * sin(phi) * sinT;

    // THE GLINT, which is the gesture: a highlight starts at a hashed angle and
    // runs one full lap while the coin tips. A von Mises bump rather than a
    // gaussian in the angle, because it wraps with no seam and no clamp.
    float glint = fl.x * exp(2.6 * (cos(phi - fl.z * 6.2831853 - fl.y * 6.2831853) - 1.0));

    // SUCCESS: the circle closes. A brighter, wider version of the same glint
    // laps the ring once on the state's own sweep, and the whole ring lifts under
    // it -- the presence's pattern is a loop, so completing it is a lap.
    float lap = st.complete * (0.45 + 1.45 * exp(3.2 * (cos(phi - st.sweep * 6.2831853 - 1.1) - 1.0)));

    float ring = (core * (1.0 + 1.15 * glint + lap) + bloom * 0.30) * crest * shim * front;

    // THE FACE. Dim amber air inside the ellipse: the coin has a body.
    float air = (1.0 - smoothstep(0.42, 1.04, k)) * (0.12 + 0.05 * waviness)
              * (0.75 + 0.45 * cosT);

    float en = (ring * 1.22 + air) * (1.0 + 0.30 * st.settled);

    MQPalette pal = mq_palette(inkColor, toneColor, hueShift, depth);
    float3 field = mq_lit(pal, en, glow, 0.0, 1.0, 0.32);

    float3 inkLin = mq_srgb_to_linear(float3(inkColor.rgb));
    return mq_finish(field, inkLin, mq_containment(uv, 0.62), position, pixelScale);
}

// MARK: - 2. Nucleus

// NUCLEUS. A steady core wearing a shell of circulating mist.
//
// THE REACTIVE SIGNATURE: `level` SWELLS THE SHELL. The core does not move. That
// restraint is the design: a presence whose centre is rock steady while its
// atmosphere breathes with the room reads as attentive, where a presence that
// pulses all over reads as agitated. So voice does two things and neither of them
// touches the core -- it pushes the shell's radius out by up to forty per cent
// and it thickens the mist inside it. Quiet room, tight halo. Someone speaking,
// a swelling body of warm mist around a steady light.
//
// `activity` QUICKENS THE CIRCULATION, and the circulation is the honest part.
// The mist is not a texture that spins as a disc: the rotation is SHEARED, faster
// at the inside than the outside, so the material winds around itself and the
// filaments stretch into arcs the way a real vortex does. That is one line -- the
// rotation angle gets a radial term -- and it is the difference between a
// circulating atmosphere and a spinning wheel.
//
// SUCCESS COLLAPSES THE SHELL INTO THE CORE. The shell radius is pulled to a
// quarter over the flash, a bright ring of mist rushes inward on the state's
// sweep, and the core takes the light in. The presence's pattern is a core inside
// an atmosphere; completing it is the atmosphere arriving.
//
// AT SMALL SIZE the core grows by half relative to the shell and the mist drops
// to two octaves. At 18 pt what survives is a bright dot in a warm halo, which is
// the species stated in the fewest possible marks. At 120 pt the third octave
// puts real filigree in the mist and the shear is visible as structure.
[[ stitchable ]] half4 mq_nucleus(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float coreK   = clamp(c0, 0.0, 1.0);   // how big the steady light is
    float shellK  = clamp(c1, 0.0, 1.0);   // how far the mist reaches
    float circK   = clamp(c2, 0.0, 1.0);   // how fast it winds
    float swellK  = clamp(c3, 0.0, 1.0);   // how much voice moves it

    MQState st = mq_state(stateIndex, stateTau);
    MQLive live = mq_live(level, activity, stateIndex);
    float small = mq_small(size);

    float r = length(uv);

    float Rc = mix(0.052, 0.092, coreK) * mix(1.0, 1.50, small);
    float swell = (0.10 + 0.90 * live.voice) * (0.35 + 0.65 * swellK);
    float Rs = mix(0.140, 0.215, shellK)
             * (1.0 + 0.38 * swell)
             * (1.0 - 0.16 * st.drive)          // responding tightens it
             * (1.0 - 0.74 * st.complete);      // success collapses it

    // THE SHEARED CIRCULATION. The inner mist turns nearly twice as fast as the
    // outer, which is what winds the filaments into arcs. Time enters as an
    // angle the coordinates are read at, never as a brightness.
    float shear = 1.0 + 0.95 * (1.0 - clamp(r / max(Rs, 1e-3), 0.0, 1.0));
    float spin = t * (0.20 + 0.52 * circK) * shear
               * (1.0 + 1.25 * live.pace) * (1.0 + 1.05 * st.drive);
    float cs = cos(spin), sn = sin(spin);
    float2 ruv = float2(cs * uv.x - sn * uv.y, sn * uv.x + cs * uv.y);

    // Sampled on the shell's own wrap, so the mist is painted ON a body and
    // foreshortens toward its limb instead of lying flat behind it.
    float rr = r / max(Rs, 1e-3);
    float zz = sqrt(max(1.0 - min(rr * rr, 1.0), 0.0));
    float3 P = float3(ruv / max(Rs, 1e-3), zz);
    int oct = small > 0.55 ? 2 : 3;
    float n = mq_fbm3(P * (2.35 / S) + float3(0.0, 0.0, t * 0.085), oct, 2.03, 0.52);
    float mistN = clamp(0.5 + 1.30 * n, 0.0, 1.0);

    // The shell is an annulus: clear of the core, fading out well before the rim.
    float inner = smoothstep(Rc * 0.50, Rc * 1.55, r);
    float outer = 1.0 - smoothstep(Rs * 0.74, Rs * 1.26, r);
    float mist = inner * outer * (0.26 + 0.74 * mistN) * (0.52 + 0.95 * swell);

    // THE THOUGHT, which is the gesture: the core lets a soft pulse out and it
    // travels through the mist to the shell's edge and dissolves.
    float4 fl = mq_flourish(t, 7.0);
    float pr = Rc + (Rs - Rc) * fl.y;
    float pz = (r - pr) / max(Rs * 0.24, 1e-3);
    mist += fl.x * exp(-pz * pz) * 0.42 * outer;

    // SUCCESS: the ring of mist rushes inward on the sweep and the core takes it.
    float cz = (r - mix(0.215, Rc, st.sweep)) / max(Rs * 0.20, 1e-3);
    mist += st.complete * exp(-cz * cz) * 1.15;

    // THE CORE. Steady, always. Its profile is a soft power falloff rather than a
    // gaussian so it holds a flat bright centre and then leaves quickly, which is
    // what makes it read as a small hot body instead of a blur.
    float core = exp(-pow(r / max(Rc, 1e-4), 1.85));
    float coreTex = 0.88 + 0.24 * clamp(0.5 + 1.4 * mq_noise3(float3(uv * (7.0 / S), t * 0.23)), 0.0, 1.0);
    float coreE = core * coreTex * (1.0 + 0.55 * st.complete + 0.18 * st.settled);

    // A soft key on the mist so the shell is a body in a room and not a fog.
    MQBall b = mq_ball(uv, max(Rs, 1e-3));
    float lit = 0.58 + 0.42 * b.lit;

    float en = coreE * 1.30 + mist * 1.05 * lit;

    MQPalette pal = mq_palette(inkColor, toneColor, hueShift, depth);
    float3 field = mq_lit(pal, en, glow, 0.0, 1.0, 0.32);

    float3 inkLin = mq_srgb_to_linear(float3(inkColor.rgb));
    return mq_finish(field, inkLin, mq_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 3. Iris

// IRIS. An aperture of soft light petals.
//
// THE REACTIVE SIGNATURE: `level` OPENS IT. This is the most literal listener in
// the family and that literalness is deliberate -- an aperture is the one
// mechanism everybody already reads as "taking something in". Voice opens the
// blades and admits light; silence eases them shut. It is a design that is
// legible with the sound off, which is the test the state work is held to and
// the same test applies here.
//
// SILENCE IS A SLIT, NOT A DOT. When the aperture closes it does not shrink to a
// point; it flattens into a horizontal sliver of light, the way an eye closes and
// the way a real iris leaves a line before it leaves nothing. That is one number
// -- the anisotropy of the central glow -- interpolated from 0.16 (a slit) to 1.0
// (a round pupil), and it is the difference between a presence that is resting
// and a presence that is off.
//
// THE BLADES ROTATE AS THEY CLOSE, because that is how the mechanism works: an
// iris does not slide its leaves inward, it turns them. So the twist carries a
// term in (1 - openness) and the whole rosette winds shut. `activity` adds a fine
// TREMBLE to the tips -- attention, held. The tremble is weighted by each blade's
// own lobe so it goes to zero at the seams between blades and can never tear the
// rosette open along a radius.
//
// AT SMALL SIZE the count drops from nine petals to five and the slit gets nearly
// three times as tall in relative terms, because a 0.01 uv slit at 18 pt is half
// a pixel and half a pixel is not a design. The two counts are crossfaded rather
// than switched: both are seam-free cosine fields, so mixing them is legal and a
// switch would pop.
//
// THE BODY. The blades ride a sphere's key light and limb, so the rosette is the
// FACE of a presence rather than a diagram lying flat on ink.
[[ stitchable ]] half4 mq_iris(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float petalsK = clamp(c0, 0.0, 1.0);   // how much of the ring the blades fill
    float openK   = clamp(c1, 0.0, 1.0);   // the resting aperture
    float softK   = clamp(c2, 0.0, 1.0);   // broad blades or defined ones
    float twistK  = clamp(c3, 0.0, 1.0);   // how far they turn as they work

    MQState st = mq_state(stateIndex, stateTau);
    MQLive live = mq_live(level, activity, stateIndex);
    float small = mq_small(size);
    float tiny = mq_tiny(size);

    float r = length(uv);
    float th = atan2(uv.y, uv.x);

    // THE GLANCE, which is the gesture: the iris opens a little on its own now
    // and then, the way an eye widens at something. It is what keeps the default
    // render -- silent, idle -- from being a still picture of a shut aperture.
    float4 fl = mq_flourish(t, 11.0);

    float breath = 0.5 + 0.5 * sin(t * 0.287);
    float o = clamp(mix(0.09, 0.40, openK) * (0.70 + 0.30 * breath)
                    + 0.62 * live.voice
                    + 0.50 * fl.x
                    + 0.24 * st.drive
                    + 0.85 * st.complete, 0.0, 1.0);

    // The blades turn as they close. Time gives a slow constant winding on top so
    // a held aperture is never a frozen mechanism.
    float tw = t * (0.055 + 0.135 * twistK) * (1.0 + 1.20 * live.pace + 1.0 * st.drive)
             + (1.0 - o) * 1.05 * twistK;

    // TWO COUNTS, CROSSFADED. Nine blades at the large mounts, five when tiny.
    float sharp = mix(2.7, 1.15, softK);
    float ang = th - tw;
    float lobe9 = pow(0.5 + 0.5 * cos(9.0 * ang), sharp);
    float lobe5 = pow(0.5 + 0.5 * cos(5.0 * ang), sharp * 0.82);
    float lobe = mix(lobe9, lobe5, tiny);
    float nBlend = mix(9.0, 5.0, tiny);

    // THE TREMBLE OF ATTENTION. Read on the circle at the blades' own frequency,
    // so it varies roughly per blade with no seam, and weighted by the lobe so it
    // dies at the gaps. A twelfth of the tip radius at full cadence: felt, not
    // watched.
    float trem = mq_ring_noise(ang, nBlend / 6.2831853, t * (1.5 + 2.6 * live.pace));
    float tipJit = trem * (0.10 + 0.90 * live.pace) * 0.016 * lobe;

    // The blades' inner edge: the aperture. It retracts outward as the iris opens.
    // `formScale` is the rosette's own size here -- bigger forms means a wider
    // mechanism, not a coarser texture -- clamped so the blades stay inside the
    // circle at both ends of the dial.
    float sc = clamp(mix(1.0, S, 0.60), 0.62, 1.15);
    float rin = (mix(0.042, 0.205, o) + tipJit) * sc;
    float rout = 0.325 * mix(1.0, 0.94, small) * sc;

    // The blade body, and the TIP, which is the key structure and goes cream. A
    // blade lit evenly along its length is a wedge of colour; a blade with a hot
    // inner edge is a leaf of metal catching the light coming through the hole.
    float bodyMask = smoothstep(rin - 0.030, rin + 0.055, r) * (1.0 - smoothstep(rout * 0.78, rout, r));
    float blade = lobe * bodyMask * (0.34 + 0.30 * petalsK);
    float tipz = (r - rin) / mix(0.026, 0.048, small);
    float tip = lobe * exp(-tipz * tipz) * (0.62 + 0.55 * petalsK);

    // THE APERTURE LIGHT. Closed, it is a slit; open, it is round. The slit is
    // held to a workable height at the small mounts, where the honest value would
    // be under a pixel.
    float aniso = mix(mix(0.16, 0.44, small), 1.0, smoothstep(0.02, 0.58, o));
    float ct = cos(tw * 0.35), stt = sin(tw * 0.35);
    float2 gq = float2(ct * uv.x + stt * uv.y, (-stt * uv.x + ct * uv.y) / max(aniso, 1e-3));
    float gw = (0.048 + 0.115 * o) * mix(1.0, 1.20, small) * sc;
    float aperture = exp(-pow(length(gq) / gw, 1.7)) * (0.42 + 0.95 * o);

    // SUCCESS: the light floods out through the blades. A bright ring travels the
    // radius on the state's sweep -- the aperture's own pattern, completed.
    float fz = (r - st.sweep * rout * 1.05) / 0.055;
    float flash = st.complete * exp(-fz * fz) * (0.55 + 0.75 * lobe) * 1.35;

    // The rosette is a face on a body: the key light and the limb make it round.
    MQBall b = mq_ball(uv, 0.335);
    float shade = (0.62 + 0.38 * b.lit) * (0.55 + 0.45 * b.limb);

    float en = (aperture * 1.20 + tip * (0.72 + 0.55 * o) + blade + flash) * shade
             * (1.0 + 0.20 * st.settled);

    MQPalette pal = mq_palette(inkColor, toneColor, hueShift, depth);
    float3 field = mq_lit(pal, en, glow, 0.0, 1.0, 0.32);

    float3 inkLin = mq_srgb_to_linear(float3(inkColor.rgb));
    return mq_finish(field, inkLin, mq_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 4. Filament

/// The thread's parameters, gathered so the curve can be evaluated at any u by
/// one function that the distance loop calls twice per segment.
struct MQThread {
    float R0;       // the loop's radius
    float a;        // the coil's amplitude: how far it winds off the loop
    float m;        // turns in the coil. INTEGER, or the thread does not close
    float k2, k3;   // the knot's radial and tangential excursions
    float kz;       // the knot's excursion out of the plane
    float ph;       // the slow re-tying
    float taut;     // responding: stretched and flattened
    float kinkU;    // the gesture's position along the thread
    float kinkAmp;  // and its size
};

/// One point on the thread, at parameter u in 0...1.
///
/// The TANGENTIAL excursion is the important term and it is the one a first cut
/// would leave out. A curve written as a radius that varies with angle can never
/// cross itself -- it is star-shaped by construction, and a thread that cannot
/// cross itself cannot knot. Pushing the point ALONG its own tangent as well
/// makes the radius multivalued in the polar angle, so the projection genuinely
/// overlaps and the crossings the eye reads as a knot are real crossings.
static float3 mq_thread_point(float u, MQThread p) {
    float ang = u * 6.2831853;
    float ca = cos(ang), sa = sin(ang);
    float cm = cos(p.m * ang + p.ph * 1.7), sm = sin(p.m * ang + p.ph * 1.7);

    float du = u - p.kinkU;
    du -= floor(du + 0.5);                      // the shortest way round the loop
    float kick = p.kinkAmp * exp(-(du * du) / (0.055 * 0.055));

    float rad = p.R0 + p.a * cm + p.k2 * p.R0 * sin(2.0 * ang + p.ph * 1.1) + kick * 0.11;
    float2 xy = float2(ca, sa) * rad
              + float2(-sa, ca) * (p.k3 * p.R0 * sin(3.0 * ang + p.ph * 1.4));
    float z = p.a * sm + p.kz * p.R0 * sin(3.0 * ang + p.ph * 0.8 + 1.4) + kick * 0.06;

    xy = float2(xy.x * (1.0 + 0.34 * p.taut), xy.y * (1.0 - 0.30 * p.taut));
    return float3(xy, z);
}

// FILAMENT. One continuous thread of light.
//
// THE LAW OF THIS SPECIES IS A NEGATIVE ONE: the thread never breaks and never
// branches. It is a single closed curve at every setting of every dial and in
// every state, which is why it is built as a parametric loop and sampled, rather
// than as a level set of a field -- a level set will happily pinch in two, and a
// thread in two pieces is a different species.
//
// THE REACTIVE SIGNATURE: `activity` TIES THE KNOT. At rest the thread is a COIL:
// a fine spring bent round into a ring, five turns at the large mounts. As cadence
// rises the coil unwinds and its excursions grow until the loop is genuinely
// knotted, crossing itself in projection with the near strand passing brightly in
// front of the far one. Responding PULLS IT TAUT: the knot flattens out, the loop
// stretches along one axis and the tube thins, which is what tension looks like.
// `level` runs CURRENT along its length -- packets of brightness travelling the
// thread, faster and stronger the louder the room, and at silence a slow shimmer
// that never quite stops, because a wire with nothing in it is not a presence.
//
// HOW THE CROSSINGS WORK. The loop is walked in 32 segments and each pixel takes
// the strongest of the 32 tube contributions rather than the nearest -- strongest,
// because each contribution is already weighted by its depth, so where two parts
// of the thread overlap on screen the nearer one wins and the far one is dimmed
// behind it. That is occlusion for the cost of a max. 32 segments is the number
// where the faceting disappears at 300 pt; it is also this file's most expensive
// species by some way, which is a price worth paying exactly once.
//
// AT SMALL SIZE the coil unwinds from five turns to three and the tube more than
// doubles in relative width. At 18 pt what is left is a bright bent loop with one
// clear crossing: not a ring, which is the halo's shape, and not a scribble.
[[ stitchable ]] half4 mq_filament(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float lenK    = clamp(c0, 0.0, 1.0);   // how much thread there is
    float knotK   = clamp(c1, 0.0, 1.0);   // how readily it ties
    float brightK = clamp(c2, 0.0, 1.0);   // the current in the wire
    float swayK   = clamp(c3, 0.0, 1.0);   // how much it moves at rest

    MQState st = mq_state(stateIndex, stateTau);
    MQLive live = mq_live(level, activity, stateIndex);
    float small = mq_small(size);
    float tiny = mq_tiny(size);

    float4 fl = mq_flourish(t, 19.0);

    float taut = st.drive;
    float Kn = clamp(mix(0.20, 0.80, knotK) * (0.40 + 1.05 * live.pace)
                     + 0.10 * swayK, 0.0, 1.0) * (1.0 - 0.72 * taut);

    MQThread p;
    p.m  = tiny > 0.5 ? 3.0 : 5.0;
    p.R0 = (0.196 + 0.030 * lenK) * (1.0 + 0.10 * Kn) * mix(1.0, 0.94, small);
    p.a  = (0.040 + 0.026 * lenK) * (1.0 - 0.62 * Kn) * (1.0 - 0.35 * taut);
    p.k2 = 0.30 * Kn;
    p.k3 = 0.26 * Kn;                       // the term that makes crossings real
    p.kz = 0.28 * Kn + 0.06;
    p.ph = t * (0.17 + 0.30 * swayK + 0.55 * live.pace) * (1.0 + 0.8 * st.drive);
    p.taut = taut;
    // THE FLICK, which is the gesture: one stretch of the thread swings wide and
    // the kink travels a third of the way round before it settles back.
    p.kinkU = fract(fl.z + fl.y * 0.34);
    p.kinkAmp = fl.x;

    float w = 0.0155 * mix(1.0, 2.35, small) * (1.0 - 0.22 * taut);
    float w2 = w * w;
    float halo = 0.0;

    float bestE = 0.0, bestU = 0.0;
    float3 A = mq_thread_point(0.0, p);
    for (int i = 0; i < 32; i++) {
        float u1 = float(i + 1) * (1.0 / 32.0);
        float3 B = mq_thread_point(u1, p);

        float2 pa = uv - A.xy, ba = B.xy - A.xy;
        float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-7), 0.0, 1.0);
        float2 dv = pa - ba * h;
        float d2 = dot(dv, dv);

        // Depth. The thread lies within about 0.09 uv of the plane, so that is
        // the span the front-to-back weighting is normalised over.
        float zz = mix(A.z, B.z, h);
        float dw = 0.58 + 0.42 * clamp(zz / 0.090, -1.0, 1.0);

        float g = exp(-d2 / w2) * dw;
        if (g > bestE) { bestE = g; bestU = (float(i) + h) * (1.0 / 32.0); }
        halo = max(halo, exp(-d2 / (w2 * 11.0)) * dw);

        A = B;
    }

    // THE CURRENT. Three packets around the loop, travelling. At silence the
    // modulation is a slow shimmer between 0.62 and 1.0; with voice the packets
    // sharpen and run, and the wire has something in it.
    float wave = 0.5 + 0.5 * sin(6.2831853 * (bestU * 3.0 - t * (0.28 + 0.62 * live.voice)));
    float cur = mix(0.62, 1.0, wave)
              * (1.0 + (0.25 + 1.15 * live.voice) * (0.35 + 0.65 * brightK) * pow(wave, 3.0));

    // SUCCESS: THE CIRCUIT CLOSES. One pulse runs the whole length once on the
    // sweep and the thread lifts behind it. The species is a loop; completing a
    // loop is going all the way round it.
    float su = bestU - st.sweep;
    su -= floor(su + 0.5);
    cur += st.complete * (1.75 * exp(-(su * su) / (0.085 * 0.085)) + 0.45);

    // A dim breath of air inside the loop, so the thread is a presence holding a
    // space rather than a wire drawn on ink.
    float air = (1.0 - smoothstep(0.30, 1.15, length(uv) / max(p.R0, 1e-3)))
              * 0.105 * (0.7 + 0.5 * clamp(0.5 + mq_noise3(float3(uv * (3.4 / S), t * 0.09)), 0.0, 1.0));

    float en = (bestE * cur * 1.15 + halo * 0.26 * cur + air) * (1.0 + 0.22 * st.settled);

    MQPalette pal = mq_palette(inkColor, toneColor, hueShift, depth);
    float3 field = mq_lit(pal, en, glow, 0.0, 1.0, 0.34);

    float3 inkLin = mq_srgb_to_linear(float3(inkColor.rgb));
    return mq_finish(field, inkLin, mq_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 5. Flare

// FLARE. A small sun that grows tongues when it hears you.
//
// THE BANNED SHAPE IS THE BRIEF. Ask for a voice meter on a circle and every
// reflex produces the same object: evenly spaced radial spikes, longer when
// louder. It is the shape of a hundred assistants and it is the shape this
// species exists to refuse. So the rule here is that the licks are never
// COUNTED and never SPACED -- their positions, widths and heights all come out
// of a noise field read around the limb, so there are five of them and then
// three, and one is fat and one is a wisp, and none of them is where the last
// one was. If you can count them from across the room the shader is wrong.
//
// THE REACTIVE SIGNATURE: `level` GROWS THE LICKS. Height is the reach field
// times voice, and reach is nothing but a distance, so a quiet room gives a limb
// that simmers and a spoken sentence gives tongues that reach out a third of the
// disc's radius and fall back. `activity` WARMS THE SIMMER: the granulation on
// the disc turns over faster and with more contrast, which is what a body under
// load actually does.
//
// WHY THEY LOOK LIKE FLAME AND NOT LIKE SPIKES. Two things. The tongues are
// SHEARED: the angle they are read at rotates with radius, by an amount that
// varies around the limb and changes sign, so each tongue leans its own way and
// curls instead of pointing straight out. And they are gaussian in the radial
// direction rather than stepped, so they have no tip -- they thin and go. A
// straight, hard-ended radial mark is a spike; a leaning, fading one is a flame.
//
// THE HARD CAP. The lick height is clamped at 0.16 uv, which is the one place in
// this file a form is limited by a number rather than by a falloff. Full voice
// with the prominence gesture on top would otherwise put a tongue past the
// circle clip, and a sliced flame is the most obvious tell in the pack. The cap
// is never reached by the design, only by the extremes.
[[ stitchable ]] half4 mq_flare(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float discK  = clamp(c0, 0.0, 1.0);   // how much of the frame is body
    float licksK = clamp(c1, 0.0, 1.0);   // how finely the limb is divided
    float reachK = clamp(c2, 0.0, 1.0);   // how far a tongue can go
    float flickK = clamp(c3, 0.0, 1.0);   // how restless they are

    MQState st = mq_state(stateIndex, stateTau);
    MQLive live = mq_live(level, activity, stateIndex);
    float small = mq_small(size);

    float r = length(uv);
    float th = atan2(uv.y, uv.x);

    float Rd = mix(0.140, 0.196, discK) * mix(1.0, 1.16, small);

    // THE DISC. Granulation on a slowly turning body: the surface of a star, not
    // a gradient. Cadence warms it -- faster turnover, more contrast -- which is
    // the species' second response and the quieter one.
    MQBall b = mq_ball(uv, Rd);
    float3 P = mq_spin(b.p, t * 0.105 * (1.0 + 0.85 * live.pace + 0.9 * st.drive), 0.17);
    float gf = 2.9 / S;
    float gran = mq_fbm3(P * gf + float3(0.0, 0.0, t * (0.085 + 0.24 * live.pace)),
                         3, 2.03, 0.53) * mq_aa(6.2831853 * gf / max(Rd, 1e-3) * 0.25, size, pixelScale);
    float g01 = clamp(0.5 + (1.15 + 0.55 * live.pace) * gran, 0.0, 1.0);
    // Limb darkening: the centre is hot and reaches cream, the edge is amber.
    float disc = b.m * (0.52 + 0.62 * g01) * (0.58 + 0.62 * pow(b.z, 0.70));

    // THE SHEAR. Each tongue leans its own way because the rotation applied to
    // the angle varies around the limb and changes sign. Responding adds a
    // constant to it, so the whole corona leans one way: a solar wind.
    float curl = mq_ring_noise(th, 1.15 / S, t * 0.043 + 31.0);
    float shear = (curl * 2.6 + st.drive * 0.85) * (r - Rd) * 8.5;
    float ths = th + shear;

    // THE LICK FIELD. Two ring-noise reads: one places and widths the tongues,
    // one flickers them. Neither is periodic in a way the eye can catch, and both
    // close around the circle by construction.
    float lf = mix(0.55, 1.25, licksK) * mix(1.0, 0.58, small) / S;
    float n1 = mq_ring_noise(ths - t * 0.115, lf, t * 0.19);
    float n2 = mq_ring_noise(ths + t * 0.085, lf * 2.15, t * 0.37 + 17.0);
    float tongue = pow(clamp(0.5 + 1.55 * n1, 0.0, 1.0), 1.7)
                 * (1.0 - flickK * 0.45 + flickK * 0.90 * clamp(0.5 + 1.4 * n2, 0.0, 1.0));

    // THE PROMINENCE, which is the gesture: one tongue arcs out much further than
    // the rest, curls hard, and falls back. Aperiodic, deterministic, and gone.
    float4 fl = mq_flourish(t, 13.0);
    float prom = fl.x * exp(3.0 * (cos(th - fl.z * 6.2831853) - 1.0));

    float reach = (0.017 + 0.098 * live.voice) * mix(0.62, 1.22, reachK)
                * (1.0 + 1.30 * prom) * (1.0 + 1.15 * st.complete);
    float h = min(reach * tongue, 0.16);

    // The flame itself. Gaussian outward from just inside the limb, so the
    // tongues grow OUT OF the body with no join, and thin away with no tip.
    float u = (r - Rd * 0.93) / max(h, 1e-4);
    float lick = exp(-u * u * 1.5) * smoothstep(Rd * 0.62, Rd * 0.99, r) * (0.28 + 0.72 * tongue);

    // SUCCESS: the flare. A corona surges out through the tongues on the sweep --
    // the sun's own pattern, all of it at once, for one breath.
    float cz = (r - (Rd + 0.15 * st.sweep)) / 0.048;
    float corona = st.complete * exp(-cz * cz) * (0.42 + 0.85 * tongue) * 1.30;

    float en = (disc * 1.16 + lick * 1.05 + corona) * (1.0 + 0.24 * st.settled);

    MQPalette pal = mq_palette(inkColor, toneColor, hueShift, depth);
    float3 field = mq_lit(pal, en, glow, 0.0, 1.0, 0.34);

    float3 inkLin = mq_srgb_to_linear(float3(inkColor.rgb));
    return mq_finish(field, inkLin, mq_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 6. Braid

// BRAID. Two strands orbiting a common centre, which is the conversation itself.
//
// THE SEMANTICS ARE THE DESIGN. One strand is the person and one is the
// assistant. `level` shifts the glow between them, so the strand that is speaking
// is the strand that is bright, and responding hands the light to the other one.
// Nobody has to be told this to feel it; a pair of things where the light moves
// back and forth is a conversation before it is a graphic.
//
// `activity` TIGHTENS THE TWIST and responding BRAIDS THEM CLOSE: separation
// shrinks with cadence and again with drive, so a busy exchange is a tight cord
// and an idle one is two loose orbits drifting apart. Note that idle needs no
// branch: separation is written as (1 - tightness) and idle is where tightness is
// zero. A state whose behaviour falls out of the arithmetic is more robust than a
// state that has to be detected.
//
// THE GEOMETRY IS CLOSED-FORM, and that is worth a sentence because the obvious
// implementation is not. Two strands wound round a ring is a pair of helices on a
// torus, and a helix on a torus is a radius and a height that are both cosines of
// the same angle: r(theta) = R + s cos(n theta + phase) and z = s sin(...). So the
// distance from any pixel to either strand is one subtraction, corrected for the
// strand's own slope, with no marching and no loop at all. The two strands are
// half a turn out of phase, which puts their projected crossings exactly where
// their heights are furthest apart -- so at every crossing one is unambiguously
// in front, which is what makes it read as a braid rather than as a plait drawn
// flat.
//
// n MUST BE AN INTEGER or the strands do not close, and a strand with a break in
// it is a broken thing. So the twist dial snaps to whole crossings. What is
// continuous instead is the winding SPEED and the separation, which is where the
// live signals do their work anyway.
[[ stitchable ]] half4 mq_braid(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float strandK = clamp(c0, 0.0, 1.0);   // the cords' weight
    float twistK  = clamp(c1, 0.0, 1.0);   // how many crossings
    float sepK    = clamp(c2, 0.0, 1.0);   // how far apart they can drift
    float balK    = clamp(c3, 0.0, 1.0);   // whose light it is at rest

    MQState st = mq_state(stateIndex, stateTau);
    MQLive live = mq_live(level, activity, stateIndex);
    float small = mq_small(size);
    float tiny = mq_tiny(size);

    float r = max(length(uv), 1e-4);
    float th = atan2(uv.y, uv.x);

    // `formScale` is the loop's own size: a bigger braid, not a finer one. The
    // clamp keeps the outer strand inside the circle at the top of the dial.
    float sc = clamp(mix(1.0, S, 0.60), 0.62, 1.15);
    float R = 0.205 * mix(1.0, 0.95, small) * sc;
    float n = floor(mix(2.0, 5.0, twistK) + 0.5);
    n = tiny > 0.5 ? max(n - 1.0, 2.0) : n;

    float tight = clamp(0.55 * live.pace + 0.85 * st.drive, 0.0, 1.0);
    float sep = mix(0.038, 0.082, sepK) * sc * (1.15 - 0.70 * tight) * (1.0 - 0.88 * st.complete);

    float wind = t * (0.26 + 0.50 * twistK) * (1.0 + 1.15 * live.pace) * (1.0 + 1.20 * st.drive);

    // THE LOOP, which is the gesture: one strand alone swings wide for a breath
    // and comes back, the way a cord slips and is taken up again.
    float4 fl = mq_flourish(t, 23.0);
    float bump = fl.x * exp(3.2 * (cos(th - fl.z * 6.2831853 - fl.y * 2.6) - 1.0));

    float tw = mix(0.013, 0.024, strandK) * mix(1.0, 2.30, small);
    float tw2 = tw * tw;

    // WHOSE LIGHT. 1 is the person, 0 is the assistant. Voice hands it one way,
    // responding hands it the other, and the resting balance is the dial.
    float bal = clamp(balK + 0.60 * live.voice - 0.58 * st.drive, 0.0, 1.0);

    float e0 = 0.0, e1 = 0.0, h0 = 0.0, h1 = 0.0, front0 = 0.0, front1 = 0.0;
    for (int k = 0; k < 2; k++) {
        float psi = n * th + wind + float(k) * 3.14159265;
        float sk = sep * (1.0 + (k == 0 ? 1.45 * bump : 0.0));
        float rk = R + sk * cos(psi);
        float zk = sk * sin(psi);
        // The strand's slope in the radial direction, which turns a difference of
        // radii into a perpendicular distance. Without it the cords fatten
        // wherever they are climbing, which reads as a lumpy rope.
        //
        // The correction is CLAMPED, and it has to be. It is 1/cos of the angle
        // between the strand and the circumference, which at the steepest setting
        // in the dial's range is 2.2 -- but the r in its denominator sends it to
        // infinity at the centre of the frame, and an infinite correction divides
        // the honest distance down to nothing and lights a bright dot in the
        // middle of the braid. 2.6 is past anything the geometry can legitimately
        // ask for, so the clamp costs nothing where the strands actually are.
        float drdth = -sk * n * sin(psi);
        float corr = clamp(sqrt(1.0 + (drdth * drdth) / (r * r)), 1.0, 2.6);
        float d = (r - rk) / corr;
        float g = exp(-(d * d) / tw2);
        float hgl = exp(-(d * d) / (tw2 * 10.0));
        float fr = 0.56 + 0.44 * (zk / max(sep, 1e-4));
        if (k == 0) { e0 = g; h0 = hgl; front0 = fr; }
        else        { e1 = g; h1 = hgl; front1 = fr; }
    }

    float g0 = (0.55 + 0.92 * bal) * front0;
    float g1 = (0.55 + 0.92 * (1.0 - bal)) * front1;
    float s0 = e0 * g0, s1 = e1 * g1;

    // The nearer strand wins where they cross; a little of the far one survives
    // behind it, because a cord is not opaque and a hard occlusion at this scale
    // reads as a cut.
    float cord = max(s0, s1) + 0.28 * min(s0, s1);
    float bloom = (h0 * g0 + h1 * g1) * 0.22;

    // SUCCESS: THEY BRAID INTO ONE. Separation has already collapsed above; here
    // the light travels the single cord once round on the sweep.
    float flash = st.complete * exp(2.8 * (cos(th - st.sweep * 6.2831853 - 0.9) - 1.0)) * 1.45;

    // The air the two of them are turning in.
    float air = (1.0 - smoothstep(0.25, 1.20, r / (R + sep))) * 0.11;

    float en = (cord * (1.20 + flash) + bloom + air) * (1.0 + 0.22 * st.settled);

    MQPalette pal = mq_palette(inkColor, toneColor, hueShift, depth);
    float3 field = mq_lit(pal, en, glow, 0.0, 1.0, 0.33);

    float3 inkLin = mq_srgb_to_linear(float3(inkColor.rgb));
    return mq_finish(field, inkLin, mq_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 7. Mote

/// The mote's path and its exact velocity. Two harmonics whose periods divide, so
/// the path CLOSES and the light returns to where it began instead of drifting
/// off; the velocity is the analytic derivative, because the lean is a lean into
/// the direction the mote is actually travelling and a finite difference would
/// wobble it.
struct MQPath { float2 c; float2 v; };

static MQPath mq_mote_path(float ph, float w0, float rate) {
    MQPath o;
    o.c = w0 * float2(cos(ph) + 0.30 * cos(2.0 * ph + 1.1),
                      0.86 * sin(ph) + 0.22 * sin(3.0 * ph + 0.5));
    o.v = w0 * rate * float2(-sin(ph) - 0.60 * sin(2.0 * ph + 1.1),
                              0.86 * cos(ph) + 0.66 * cos(3.0 * ph + 0.5));
    return o;
}

// MOTE. The minimal presence, and the only one in Murmur designed at 18 pt first.
//
// EVERYTHING ELSE IN THE PACK WAS DESIGNED BIG AND TAUGHT TO SURVIVE SMALL. This
// one was drawn at 18 points inside a text field -- one soft light, wandering --
// and then given permission to grow structure at the large mounts. That order
// matters: a species designed at 300 pt and shrunk becomes a smudge, because
// everything that made it interesting was smaller than a pixel. Here the whole
// idea is legible in a single glowing mark, and the granulation, the corona and
// the tail's fine wisp are things the large mount gets as a bonus.
//
// THE REACTIVE SIGNATURE: `activity` MAKES IT LEAN. The mote quickens along its
// path, and -- the part that sells it -- its body leans into the leading edge:
// the peak shifts forward of centre, the front tightens and the back stretches.
// It is the shape a thing takes when it is going somewhere, and it reads at 18 pt
// where nothing else would. `level` STRETCHES IT along its motion, so a spoken
// sentence draws the light out into a soft streak and silence lets it round back
// up. Neither response is a brightness change; both are shape.
//
// CALM IS THE SPECIFICATION. This is the stillest species in Murmur and it must
// stay that way: the path is small, the rate is low, the drift underneath it is a
// two-octave fBm on a seventy-second scale so the loop is never twice the same,
// and the dart -- the gesture -- is a single soft excursion and back. Nothing
// here is watched. It is felt out of the corner of the eye, which is the correct
// behaviour for a light living in a text field somebody is typing into.
//
// SUCCESS IS THE ONE TIME THE PATH IS VISIBLE. The route the mote has been
// quietly walking lights up as a thin trace and a flash runs it once round. The
// species' own pattern is a circuit; completing it is showing the circuit. The
// trace loop is guarded on the state, and stateIndex is uniform across the draw,
// so it costs exactly nothing in every other state.
[[ stitchable ]] half4 mq_mote(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float wanderK = clamp(c0, 0.0, 1.0);   // how far it roams
    float leanK   = clamp(c1, 0.0, 1.0);   // how hard it leans when busy
    float sizeK   = clamp(c2, 0.0, 1.0);   // the light itself
    float tailK   = clamp(c3, 0.0, 1.0);   // what it leaves behind

    MQState st = mq_state(stateIndex, stateTau);
    MQLive live = mq_live(level, activity, stateIndex);
    float small = mq_small(size);

    float w0 = (0.085 + 0.055 * wanderK) * mix(1.0, 0.86, small);
    float rate = (0.30 + 0.34 * wanderK) * (1.0 + 1.30 * live.pace) * (1.0 + 1.05 * st.drive);
    float ph = t * rate;

    MQPath path = mq_mote_path(ph, w0, rate);
    float2 c = path.c;
    float2 v = path.v;

    // The slow drift under the loop: the path itself wanders, so the mote never
    // traces the same circuit twice and no frame is ever a repeat of an old one.
    c += 0.030 * float2(mq_fbm1(t * 0.068, 2, 3.0), mq_fbm1(t * 0.068 + 11.0, 2, 29.0));

    // THE DART, which is the gesture: a soft excursion off the path and back. Its
    // contribution to the VELOCITY is included, which is why mq_flourish returns
    // the gesture's duration -- the lean has to stay honest while the mote is
    // being carried sideways, or the light leans the wrong way for a second and
    // the whole illusion of intent comes apart.
    float4 fl = mq_flourish(t, 29.0);
    float2 dartDir = float2(cos(fl.z * 6.2831853), sin(fl.z * 6.2831853));
    c += dartDir * fl.x * 0.052;
    v += dartDir * 0.052 * 3.14159265 * sin(6.2831853 * fl.y) / max(fl.w, 0.5);

    float sp = max(length(v), 1e-5);
    float2 dh = v / sp;
    float2 q = uv - c;
    float al = dot(q, dh);
    float ac = dot(q, float2(-dh.y, dh.x));

    // THE LIGHT. Half again as big at 18 pt, because a sigma of 0.035 uv there is
    // two pixels and two pixels is a speck rather than a presence.
    float s0 = mix(0.030, 0.052, sizeK) * mix(1.0, 1.55, small);
    float lean = leanK * (0.20 + 0.95 * live.pace);
    al -= lean * s0 * 0.80;                        // the peak moves forward

    float sa = s0 * (1.0 + 0.85 * live.voice);     // voice stretches it
    float sc = s0 * (1.0 - 0.16 * live.voice);
    float sAl = al > 0.0 ? sa * (1.0 - 0.34 * lean)     // tight in front
                         : sa * (1.0 + 0.55 * lean);    // long behind
    float core = exp(-(al * al) / (sAl * sAl) - (ac * ac) / (sc * sc));

    // The wake. Only behind, gated smoothly so it never doubles the front edge.
    float back = smoothstep(0.0, s0 * 0.55, -al);
    float tail = (0.20 + 0.75 * tailK) * back
               * exp(al / (s0 * (2.8 + 4.0 * tailK)))
               * exp(-(ac * ac) / (sc * sc * 2.4));

    // What the large mount gets: granulation inside the light and a fine corona.
    // Faded out entirely by 18 pt, where it would be sub-pixel sparkle.
    float fine = (1.0 - small) * 0.26
               * mq_fbm3(float3(q * (7.5 / S), t * 0.19), 2, 2.03, 0.50);
    float corona = exp(-dot(q, q) / (s0 * s0 * 9.0)) * (0.13 + 0.10 * tailK);

    float en = (core * (1.0 + fine) * 1.22 + tail * 0.55 + corona);

    // SUCCESS: the circuit is shown. Twenty-four segments of the path, the
    // nearest one lit, and a flash running it once round on the sweep. Guarded on
    // a uniform, so it is free everywhere else.
    if (st.complete > 0.002) {
        float bestD = 1e9, bestU = 0.0;
        MQPath A = mq_mote_path(ph, w0, rate);
        for (int i = 0; i < 24; i++) {
            float u1 = float(i + 1) * (1.0 / 24.0);
            MQPath B = mq_mote_path(ph + u1 * 6.2831853, w0, rate);
            float2 pa = uv - A.c, ba = B.c - A.c;
            float hh = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-7), 0.0, 1.0);
            float2 dv = pa - ba * hh;
            float d2 = dot(dv, dv);
            if (d2 < bestD) { bestD = d2; bestU = (float(i) + hh) * (1.0 / 24.0); }
            A = B;
        }
        float trw = 0.011 * mix(1.0, 1.9, small);
        float trace = exp(-bestD / (trw * trw));
        float su = bestU - st.sweep;
        su -= floor(su + 0.5);
        en += st.complete * trace * (0.40 + 1.45 * exp(-(su * su) / (0.075 * 0.075)));
    }

    en *= (1.0 + 0.24 * st.settled);

    MQPalette pal = mq_palette(inkColor, toneColor, hueShift, depth);
    float3 field = mq_lit(pal, en, glow, 0.0, 1.0, 0.34);

    float3 inkLin = mq_srgb_to_linear(float3(inkColor.rgb));
    return mq_finish(field, inkLin, mq_containment(uv, 0.60), position, pixelScale);
}

// MARK: - 8. Ripple

// RIPPLE. A still liquid disc where input lands.
//
// RINGS ARE BANNED EVERYWHERE ELSE IN MURMUR and they are honest here, which is
// the whole reason this species exists. The pack's echo rejected concentric
// circles because nothing was actually arriving; here something is. A keystroke
// lands, a token arrives, and a ring leaves the point it landed on. The rule that
// replaces the ban is: SOFT AND FEW. Five impulse slots of history, a probability
// that is a tenth at rest, crests wide enough to have no edge, and every ring
// dead well before the rim.
//
// THE REACTIVE SIGNATURE: DISCRETE IMPULSES FROM `activity`, WITH NO STATE
// BETWEEN FRAMES. This is the one species whose response is an EVENT rather than
// a level, and events are exactly what a shader cannot remember. So they are
// derived instead: time is cut into 0.55 s slots, each slot's fate is a hash of
// its index, and a slot fires if its hash falls under a probability set by
// cadence. Onset, origin and size are all further hashes of the same index. Any
// t at all therefore renders the correct frame, a scrubbed slider agrees with a
// running app, and a screenshot rig catches the rings exactly where the animation
// would have had them. Determinism was not a constraint on this design; it is the
// mechanism of it.
//
// `level` RAISES A STANDING TREMBLE: three travelling modes across the whole
// surface, small, so that a room with a voice in it has a live surface and a
// silent one is glass. The modes are sinusoids rather than noise for one specific
// reason -- this species lights its surface by its SLOPE, and a sinusoid's slope
// is another sinusoid, exact and free, where a noise field's would have cost two
// more taps and a finite difference.
//
// WHY IT LOOKS LIKE WATER. The rings are not drawn as bright circles. They are a
// HEIGHT FIELD, and what is drawn is the light reflecting off the surface that
// height implies: the leading face of a crest turns toward the key and goes
// cream, the trailing face turns away and goes dark, and the pair of them is what
// the eye has always read as a ripple. A bright ring painted on a flat disc is a
// target; a tilted surface is water.
//
// AT SMALL SIZE the crests widen, the finest tremble mode is gated out by the
// anti-alias test rather than by a size rule (the honest gate, since it is a
// chosen frequency), and the dome deepens so an 18 pt pool still reads as a
// meniscus and not a coin.
[[ stitchable ]] half4 mq_ripple(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float stillK = clamp(c0, 0.0, 1.0);   // how quiet the resting surface is
    float spdK   = clamp(c1, 0.0, 1.0);   // how fast a ring travels out
    float decayK = clamp(c2, 0.0, 1.0);   // how long it lives
    float sheenK = clamp(c3, 0.0, 1.0);   // how tight the light on the water is

    MQState st = mq_state(stateIndex, stateTau);
    MQLive live = mq_live(level, activity, stateIndex);
    float small = mq_small(size);

    float Rp = 0.300 * mix(1.0, 0.98, small);
    float r = length(uv);
    MQBall b = mq_ball(uv, Rp);

    // THE HEIGHT FIELD AND ITS SLOPE, built together. Everything that touches the
    // surface adds to both, and nothing is ever added to one alone -- that is the
    // invariant that keeps the light honest.
    float h = 0.0;
    float2 dh = float2(0.0);

    // The meniscus: the pool stands slightly proud in the middle, which is what
    // gives the resting surface its broad soft sheen off to one side.
    float domeH = 0.020 * mix(1.0, 1.35, small);
    h  += domeH * (1.0 - (r * r) / (Rp * Rp));
    dh += -2.0 * domeH * uv / (Rp * Rp);

    // THE STANDING TREMBLE. Three modes, incommensurate, slowly turning so no
    // standing pattern ever settles into a plaid. Voice raises them; a tenth
    // survives at silence so the glass is never dead.
    float trA = (0.055 + 0.945 * live.voice) * mix(0.45, 1.0, 1.0 - stillK) * 0.0085;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float a = 0.9 + fi * 2.2 + t * (0.031 + 0.017 * fi);
        float f = (21.0 + 13.0 * fi) / S;
        float2 kv = float2(cos(a), sin(a)) * f;
        float w = 1.35 + 0.45 * fi;
        float gate = mq_aa(f, size, pixelScale);         // the finest mode first
        float amp = trA * (1.0 - 0.25 * fi) * gate;
        float pz = dot(uv, kv) - t * w;
        h  += amp * sin(pz);
        dh += amp * kv * cos(pz);
    }

    // THE IMPULSES. Five slots of history at 0.55 s each: two and three quarter
    // seconds, which is exactly as long as a ring stays worth looking at.
    const float SLOT = 0.55;
    float p = 0.10 + 0.78 * live.pace + 0.55 * st.drive;
    float spd = mix(0.115, 0.235, spdK);
    float life = mix(0.65, 1.15, decayK);
    float ringW = 0.038 * mix(1.0, 1.85, small);
    float slot0 = floor(t / SLOT);

    for (int i = 0; i < 5; i++) {
        float slot = slot0 - float(i);
        float fire = step(mq_hash1(slot, 71.0), p);
        float onset = slot * SLOT + SLOT * (0.12 + 0.66 * mq_hash1(slot, 137.0));
        float age = t - onset;
        float alive = fire * step(0.0, age);

        // Where it landed. Responding pulls the origins to the middle, so an
        // answering presence beats from its centre instead of being rained on.
        float oa = mq_hash1(slot, 211.0) * 6.2831853;
        float orr = 0.52 * Rp * sqrt(mq_hash1(slot, 307.0)) * (1.0 - 0.85 * st.drive);
        float2 o = float2(cos(oa), sin(oa)) * orr;

        float2 dvec = uv - o;
        float dd = max(length(dvec), 1e-5);
        float rad = spd * age;
        float x = dd - rad;
        float w = ringW * (1.0 + 0.55 * age);             // dispersion, honestly
        float amp = alive * (0.016 + 0.008 * mq_hash1(slot, 401.0))
                  * exp(-age / life)
                  * (1.0 - smoothstep(0.58, 1.0, rad / Rp))    // gone before the rim
                  / sqrt(1.0 + rad / 0.09);                    // and spreading out

        // A crest with one soft trough either side. Windowed rather than pure, so
        // it is a wave and not a bump, and its derivative is exact.
        float k = 2.2 / w;
        float env = exp(-(x * x) / (w * w));
        float cs = cos(k * x), sni = sin(k * x);
        h  += amp * env * cs;
        dh += amp * env * (-2.0 * x / (w * w) * cs - k * sni) * (dvec / dd);
    }

    // SUCCESS: one last ring, from dead centre, all the way out. The surface's own
    // pattern is a ring arriving; completing it is a ring that reaches everywhere.
    float sr = st.sweep * Rp * 1.06;
    float sx = r - sr;
    float sw = 0.055;
    float sEnv = exp(-(sx * sx) / (sw * sw)) * st.complete * 0.030;
    h  += sEnv;
    dh += sEnv * (-2.0 * sx / (sw * sw)) * (uv / max(r, 1e-5));

    // THE TILT, which is the gesture: the whole pool leans for a breath and the
    // sheen slides across it. A constant added to the slope, which is what a tilt
    // is, and the cheapest interesting thing in the file.
    float4 fl = mq_flourish(t, 37.0);
    float2 tiltDir = float2(cos(fl.z * 6.2831853), sin(fl.z * 6.2831853));
    h  += fl.x * 0.014 * dot(uv, tiltDir);
    dh += fl.x * 0.014 * tiltDir;

    // THE LIGHT ON THE WATER. Half-vector against a fixed key, so a flat surface
    // holds a soft broad sheen and a tilted one either flares to cream or falls
    // away to shadow -- the crest-and-trough pair that reads as a wave.
    float3 nrm = normalize(float3(-dh, 1.0));
    float3 H = normalize(float3(-0.216, 0.281, 1.945));
    float spec = pow(clamp(dot(nrm, H), 0.0, 1.0), mix(13.0, 32.0, sheenK));
    float diff = 0.5 + 0.5 * dot(nrm, normalize(float3(-0.40, 0.52, 0.75)));

    // The body of the liquid: dark, deep, with the limb going darker still, so
    // the sheen and the crests have somewhere to be bright against.
    float body = b.m * (0.26 + 0.30 * b.limb) * (0.70 + 0.55 * diff);
    float en = (body + b.m * spec * (0.72 + 0.55 * sheenK) * 1.30
                + b.m * max(h, 0.0) * 6.0)                 // the crests carry mass
             * (1.0 + 0.30 * st.complete + 0.18 * st.settled);

    MQPalette pal = mq_palette(inkColor, toneColor, hueShift, depth);
    float3 field = mq_lit(pal, en, glow, 0.0, 1.0, 0.32);

    float3 inkLin = mq_srgb_to_linear(float3(inkColor.rgb));
    return mq_finish(field, inkLin, mq_containment(uv, 0.60), position, pixelScale);
}
