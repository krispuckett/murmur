// The Liquid pack. Six thinking indicators made of molten weight: the pour's
// blood, none of the pour's form.
//
//   ml_eddy        thought circling a centre. A vortex's differential rotation,
//                  applied to the coordinate the material is read against, so
//                  the inner turn outruns the outer one and the mass winds into
//                  arms it did not have a moment ago.
//   ml_well        a sink. A radial remap of the plane, scrolled, carries the
//                  material inward and stretches it into wisps on the way; the
//                  throat stays dark, because a well that fills is a puddle.
//   ml_tide        a body of liquid sloshing in a bowl. The speed is a sine, the
//                  position is its exact integral, and the surface leans with
//                  the mass rather than against it.
//   ml_undertow    two sheets sliding opposite ways past each other. What is
//                  drawn is neither sheet: it is the seam where they read the
//                  same value, which belongs to both and travels with neither.
//   ml_meander     one broad channel on a single slow arc through dark ground,
//                  its banks soft dark shoulders, the light inside it
//                  travelling downstream while the arc itself re-cuts.
//   ml_confluence  two flows finding each other and joining, on their own
//                  diagonal. An arc: the approach is a law, the distance
//                  travelled is that law's exact integral, and joined is the
//                  rest state, still moving, still turning over at the meeting.
//
// WHAT THE FAMILY SHARES, AND WHY THAT IS NOT A LIMIT. These six are one
// ecosystem, not one animal. The shared blood is the material and the light:
// warm liquid light computed per pixel out of gradient noise, walked through the
// house OKLAB rail so a single hue family holds, kneed where it runs hot, and
// written once through the triangular dither. Everything ABOVE that is species:
// each one has its own body and its own physics, and no two are the same field
// with a different frequency. The pour pack's record is the reason for the rule.
// Two waves of shaders built from a DESCRIPTION of a loved material were
// rejected; the wave that started from the material's own code was not. So the
// kit here is copied, and the forms above are invented from a physics rather
// than tuned from a rule list.
//
// AND WHAT IT IS NOT. Not the pour. The pour is a wall of falling streams read
// through a window, and its whole grammar is vertical. Nothing here falls. These
// turn, sink, wash, shear, wander and join, which are six things liquid does
// that are not pouring. The one place a stream appears (meander, confluence) it
// runs ACROSS the frame, because a bright line running down a small circle is
// the pour wearing a disguise.
//
// THESE ARE INDICATORS, WHICH CHANGES THE BUDGET AND THE BAR.
//
//   the frame     every function centres with uv = (position - 0.5 size) /
//                 min(size), so the field is size-independent and correct in a
//                 non-square view. The VIEW clips to a circle at length(uv) =
//                 0.5. A clip that cuts a form is a form with a hard edge, and
//                 organic forms do not have those, so ml_bowl brings every last
//                 photon down to pure ink by length(uv) = 0.45 and the clip
//                 never has anything left to cut.
//   the ceiling   calm is the bar, and calm is mostly a ceiling. The rail runs
//                 ink -> warm shadow -> tone -> pale specular; these fields live
//                 between about 0.05 and 0.80 on it, so the brightest thing on
//                 screen is the tone with a little light behind it and the pale
//                 stop is somewhere they can reach, not somewhere they sit.
//   the tempo     motion is felt, not watched. The fastest thing in the pack
//                 crosses the disc in about eighteen seconds; most of it takes
//                 half a minute. Nothing here pulses: the family verbs are FLOW
//                 and SETTLE, and a brightness that breathes is neither.
//   the cost      fixed-count loops, fBm at three octaves, nine field taps a
//                 pixel at the worst (confluence) and three at the best (well).
//                 An indicator at 46 pt has to be free, and a 300 pt one has to
//                 hold up in a full-screen studio at the same time.
//   the light     glow drives EMISSION only, never the base. Scaling the shaded
//                 colour would darken the ink itself and put a ring around a
//                 field that is supposed to dissolve into its pill.
//
// COPIED HELPERS. Cross-file Metal linkage is not guaranteed, so the kit is
// copied out of FieldLab.metal VERBATIM under an ml_ prefix, the way the pour
// pack did it, with the comments carried along because the reasoning is the part
// worth carrying. Copied, unchanged except for the name:
//
//   ml_hash, ml_grad3, ml_noise3, ML_ROT, ml_fbm3, ml_hash1, ml_vnoise1,
//   ml_fbm1, ml_srgb_to_linear, ml_linear_to_srgb, ml_linear_to_oklab,
//   ml_oklab_to_linear, ml_lch, MLPalette, ml_palette, ml_shade, ml_out,
//   ml_knee (the last from FieldPackPour.metal, which is where the pack rail
//   and the knee were last carried together).
//
// Not copied: fl_noised3 and fl_fbmd3, because nothing here lights a surface off
// its own slope; fl_edge, because a rectangular vignette is the wrong shape for
// a circle and ml_bowl is its radial equivalent; the whole wave-two kit, because
// this pack has no journey, no streak and no perspective camera. Copying kit a
// pack never calls only leaves dead code behind a prefix.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - The copied kit
//
// Everything in this section is FieldLab.metal's (and, for the knee,
// FieldPackPour.metal's), verbatim, renamed.

/// An integer avalanche. Lattice coordinates in, well-mixed bits out. A sine
/// hash was the other option and it drifts into visible repeats once the domain
/// gets large, which the long previews here would find.
static inline uint ml_hash(uint3 v) {
    uint h = v.x * 1597334673u ^ v.y * 3812015801u ^ v.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u;
    h ^= h >> 13; h *= 3266489917u;
    h ^= h >> 16;
    return h;
}

/// A unit vector distributed uniformly on the sphere, from one lattice cell.
/// Uniform matters: gradients bunched near the poles put a grain in the field
/// that reads as a weave once the octaves stack.
static inline float3 ml_grad3(int3 c) {
    uint h = ml_hash(uint3(c + 4096));
    float z = fma(float(h & 0xFFFFu), 2.0 / 65535.0, -1.0);
    float a = float((h >> 16) & 0xFFFFu) * (6.28318530718 / 65536.0);
    float r = sqrt(max(0.0, 1.0 - z * z));
    return float3(r * cos(a), r * sin(a), z);
}

/// The value alone, for the places that never ask what the slope is: the warp
/// offsets and the sheets behind the first. Roughly a third cheaper.
static float ml_noise3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    int3 c = int3(i);

    float va = dot(ml_grad3(c + int3(0, 0, 0)), f - float3(0.0, 0.0, 0.0));
    float vb = dot(ml_grad3(c + int3(1, 0, 0)), f - float3(1.0, 0.0, 0.0));
    float vc = dot(ml_grad3(c + int3(0, 1, 0)), f - float3(0.0, 1.0, 0.0));
    float vd = dot(ml_grad3(c + int3(1, 1, 0)), f - float3(1.0, 1.0, 0.0));
    float ve = dot(ml_grad3(c + int3(0, 0, 1)), f - float3(0.0, 0.0, 1.0));
    float vf = dot(ml_grad3(c + int3(1, 0, 1)), f - float3(1.0, 0.0, 1.0));
    float vg = dot(ml_grad3(c + int3(0, 1, 1)), f - float3(0.0, 1.0, 1.0));
    float vh = dot(ml_grad3(c + int3(1, 1, 1)), f - float3(1.0, 1.0, 1.0));

    return mix(mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y),
               mix(mix(ve, vf, u.x), mix(vg, vh, u.x), u.y), u.z);
}

/// The per-octave rotation. Orthonormal, so its transpose is its inverse, which
/// is exactly what the chain rule below needs. Without it every octave stacks on
/// the same lattice axes and the field grows a visible plaid.
constant float3x3 ML_ROT = float3x3(float3( 0.00,  0.80,  0.60),
                                    float3(-0.80,  0.36, -0.48),
                                    float3(-0.60, -0.48,  0.64));

static float ml_fbm3(float3 p, int octaves, float lacunarity, float gain) {
    float3 q = p;
    float amp = 0.5;
    float value = 0.0;
    for (int i = 0; i < octaves; i++) {
        value += amp * ml_noise3(q);
        amp *= gain;
        q = lacunarity * (ML_ROT * q);
    }
    return value;
}

// MARK: 1D value noise
//
// The 3D gradient field above is the right tool when a surface has to be lit,
// and the wrong one when all that is wanted is a wandering scalar along a line:
// it costs thirty two hashes an evaluation. This costs two. The meander's
// centreline takes three of these a pixel and the confluence's two arms take
// two more, and neither would fit in a frame at the other price.

static inline float ml_hash1(float cell, float lane) {
    return float(ml_hash(uint3(uint(int(cell) + 32768), uint(int(lane) + 32768), 0x9E3779B9u)) >> 8)
         * (1.0 / 16777216.0);
}

/// Value noise on a line, quintic-interpolated so its slope is continuous and
/// a silhouette built on it has no corners the eye can find.
static inline float ml_vnoise1(float x, float lane) {
    float i = floor(x), f = x - i;
    float u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(ml_hash1(i, lane), ml_hash1(i + 1.0, lane), u) * 2.0 - 1.0;
}

/// fBm on a line. Amplitude halves, frequency a hair past doubles (2.03, so no
/// two octaves ever land on the same cell wall). Range is about plus or minus
/// one for four octaves.
static float ml_fbm1(float x, int octaves, float lane) {
    float v = 0.0, amp = 0.5, f = 1.0;
    for (int i = 0; i < octaves; i++) {
        v += amp * ml_vnoise1(x * f, lane + float(i) * 37.0);
        amp *= 0.5;
        f *= 2.03;
    }
    return v;
}

// MARK: OKLAB and the family

static inline float3 ml_srgb_to_linear(float3 c) {
    c = max(c, 0.0);
    return select(c * (1.0 / 12.92), pow((c + 0.055) * (1.0 / 1.055), 2.4), c > 0.04045);
}

static inline float3 ml_linear_to_srgb(float3 c) {
    c = max(c, 0.0);
    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c > 0.0031308);
}

static inline float3 ml_linear_to_oklab(float3 c) {
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

static inline float3 ml_oklab_to_linear(float3 lab) {
    float l_ = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
    float m_ = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
    float s_ = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
    float l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    return float3( 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                  -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                  -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

/// Lightness, chroma, hue back into OKLAB's rectangular form.
static inline float3 ml_lch(float L, float C, float h) {
    return float3(L, C * cos(h), C * sin(h));
}

/// Four OKLAB stops built from one anchor: the day tone the ribbon wears.
/// Ordered dark to bright, and never more than one hue family wide.
struct MLPalette { float3 s0, s1, s2, s3; };

/// s0 is the ink the whole app sits on, so a field at zero dissolves into the
/// screen with no seam. s1 is a deep shadow that KEEPS the tone's hue at half
/// its chroma, which is what stops the dark end going grey. s2 is the tone. s3
/// is a pale specular a few degrees warmer, because light that has passed
/// through anything comes out warmer than the thing it lit.
/// `depth` opens the range from both ends without letting the hue wander.
static MLPalette ml_palette(half4 inkColor, half4 toneColor, float hueShift, float depth) {
    float3 ink = ml_linear_to_oklab(ml_srgb_to_linear(float3(inkColor.rgb)));
    float3 tone = ml_linear_to_oklab(ml_srgb_to_linear(float3(toneColor.rgb)));

    float L = tone.x;
    float C = length(tone.yz);
    float h = atan2(tone.z, tone.y) + hueShift;
    float d = clamp(depth, 0.30, 2.00);

    // The shadow shifts WARM as it darkens, roughly twenty degrees of hue
    // toward ember, and keeps most of its chroma rather than draining to grey.
    // Both of those are the difference between a deep amber and mud: a straight
    // desaturating fall from gold to ink passes through olive, and olive is what
    // the first cut of every one of these fields looked like.
    MLPalette p;
    p.s0 = ink;
    p.s1 = ml_lch(mix(ink.x, L, 0.30 / d), C * (0.52 + 0.10 * d), h - 0.35);
    p.s2 = ml_lch(L, C, h);
    p.s3 = ml_lch(min(L * (1.20 + 0.12 * d), 0.93), C * 0.55, h + 0.10);
    return p;
}

/// Walk the family. Three segments, each eased so its ends are flat, which
/// makes the joins C1: no kink shows up as a contour line in a smooth field.
/// Returns LINEAR light; ml_out does the encoding.
static float3 ml_shade(MLPalette p, float t) {
    t = clamp(t, 0.0, 1.0);
    float3 lab;
    if (t < 0.40) {
        lab = mix(p.s0, p.s1, smoothstep(0.0, 1.0, t * 2.5));
    } else if (t < 0.78) {
        lab = mix(p.s1, p.s2, smoothstep(0.0, 1.0, (t - 0.40) * (1.0 / 0.38)));
    } else {
        lab = mix(p.s2, p.s3, smoothstep(0.0, 1.0, (t - 0.78) * (1.0 / 0.22)));
    }
    return ml_oklab_to_linear(lab);
}

/// A soft knee, the same one the route curtain uses. Below the knee nothing
/// changes; above it the tail compresses asymptotically instead of clipping,
/// which is what stops a bright field turning into flat white paper.
static inline float ml_knee(float x, float knee) {
    return x < knee ? x : knee + (1.0 - knee) * (1.0 - exp(-(x - knee) / max(1.0 - knee, 1e-3)));
}

/// The last thing every field does. One code value of triangular-PDF
/// interleaved-gradient dither, in the encoded space where the quantization
/// actually happens. Triangular rather than uniform because uniform dither
/// leaves a faint texture of its own in flat areas; triangular does not.
static inline half4 ml_out(float3 linearRGB, float2 pixel) {
    float3 c = ml_linear_to_srgb(linearRGB);
    float n = fract(52.9829189 * fract(dot(pixel, float2(0.06711056, 0.00583715))));
    float tri = n < 0.5 ? (sqrt(2.0 * n) - 1.0) : (1.0 - sqrt(max(0.0, 2.0 - 2.0 * n)));
    c += tri * (1.0 / 255.0);
    return half4(half3(saturate(c)), 1.0h);
}

// MARK: - The pack's own frame
//
// Three small things every species in this file shares. They are NOT copied kit;
// they are what makes six generative fields into six indicators.

/// THE BOWL. fl_edge's job, in the shape this pack actually lives in.
///
/// The lab's fields fade toward a rectangle because a rectangle is what they
/// fill. An indicator is a circle, and the circle is enforced by a clip in the
/// view, which is a hard edge by definition. So the light has to be gone before
/// the clip arrives: r is measured so that 1.0 is exactly the clip, the fade
/// begins at 0.54 of it and is complete at 0.90, which leaves a tenth of the
/// radius of pure ink under the rim. That last tenth is the whole point. It is
/// also why these read as a body of material floating in a pill rather than as a
/// texture stamped into a hole.
static inline float ml_bowl(float2 uv) {
    float r = length(uv) * 2.0;                  // 1.0 at the view's own circle
    return 1.0 - smoothstep(0.54, 0.90, r);
}

/// THE WRITE. Every species ends here, and the order is the argument.
///
/// `t` walks the rail and nothing else does: accent comes from moving along the
/// family, never from a second hue. `hot` is the fraction of the material that
/// is bright enough to have light of its own, and it is the ONLY thing `glow`
/// touches. That split is deliberate: the base colour at t = 0 is the ink
/// exactly, so a field with nothing in it is the pill's own ground to the bit,
/// and scaling that by a presence dial would draw a dark ring around a shape
/// that is supposed to have no shape at all.
///
/// The emission is a tonal lift, not a spatial blur. The pour needs eleven taps
/// of real Gaussian because its material is sixty sharp columns under a
/// magnification; these fields are three octaves of gradient noise and are
/// already broad, so a blur would cost eleven times the frame to soften
/// something that has no hard structure to soften. Where a species genuinely
/// wants light spilling into the air around a form (the two channel species) it
/// gets a real, wider second Gaussian in closed form, which is free.
///
/// `emRail` IS WHERE THE EMITTED LIGHT SITS ON THE RAIL, and it is a per-species
/// number because the pour pack's pv_tint comment is right and this pack proved
/// it again. Past about 0.86 the rail is walking into the pale specular, whose
/// chroma is roughly half the tone's; adding that to a field that is already at
/// the tone does not make hot amber, it makes a desaturated grey-white that
/// reads out of the family next to its neighbours. A species whose material
/// spends most of its time near the tone (undertow) has to emit BELOW that, at
/// 0.80, where the added light is still saturated. A species that is mostly dark
/// with small hot cores can safely emit at 0.88, because the pale light lands on
/// ink and not on more tone.
///
/// Then the knee at 0.90, then the dither. A hot tone with the glow up used to
/// clip and turn the crest into flat paper with banded arcs at its edge; below
/// the knee nothing changes and above it the tail compresses into light instead.
static inline half4 ml_write(MLPalette pal, float3 inkLin, float t, float hot,
                             float emRail, float glow, float contain, float2 pixel) {
    float3 lit = ml_shade(pal, t);
    float3 em = ml_shade(pal, emRail) * (0.42 * clamp(hot, 0.0, 1.5) * max(glow, 0.0));
    float3 rgb = mix(inkLin, lit + em, contain);
    rgb = float3(ml_knee(rgb.r, 0.90), ml_knee(rgb.g, 0.90), ml_knee(rgb.b, 0.90));
    return ml_out(rgb, pixel);
}

/// The centred, aspect-preserved frame every function opens with. length(uv) is
/// 0.5 at the view's circle whichever way the view is stretched.
static inline float2 ml_uv(float2 position, float2 size) {
    return (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
}

// MARK: - 1. Eddy

// EDDY. Thought circling a centre.
//
// THE PHYSICS. A vortex is not a spinning picture; it is a field whose angular
// speed depends on how far out you are. Rotate the coordinate the material is
// READ against by an angle that falls off with radius, and a blob that was round
// a moment ago is drawn out into an arm, because its inside has gone further
// round than its outside. Nothing is painted as a spiral. The spiral is what
// differential rotation does to whatever happens to be there, which is what it
// does in water.
//
//   omega(r) = W * ((R0 + RC) / (r + RC))^fall
//
// RC = 0.17 is the core's softening radius and it is doing real work: without it
// omega goes to infinity at the centre and the middle pixel winds up a hundred
// turns while its neighbour winds up two, which aliases into a hard dot. R0 =
// 0.25 is a reference ring at about half the disc, and dividing by it is what
// lets `shear` change the SHAPE of the falloff without changing the speed of the
// picture: at any shear setting the material at mid-radius turns at W, and only
// the difference between inside and outside moves. That separation is the
// difference between a knob that tightens the spiral and a knob that also speeds
// the whole thing up, and the second one is unusable.
//
// WHY IT NEVER WINDS ITSELF SHUT. Differential rotation applied forever makes
// infinitely tight spirals. Real eddies do not, because the water in them is
// continuously replaced. So is this: the noise drifts along its third axis, and
// old structure decorrelates in ten to fifteen seconds, which at these rates is
// under half a turn of winding. The field can never get tighter than that no
// matter how long the view is left running.
//
// THE CENTRE IS DIMMED, slightly and on purpose. A vortex core is a low pressure
// void: there is less material there, not more. It is also where omega is
// highest, so it is where a bright pixel would alias first. The 0.52 floor
// darkens it enough to be honest and not enough to punch a hole, which would be
// the well's job and not this one's.
//
//   c0 swirl   how fast the turn goes at mid-radius
//   c1 drift   how far the core wanders across the disc, and how fast old
//              structure is replaced (one dial, because they are one idea: a
//              turn that stays put and never renews is a wallpaper)
//   c2 grain   a fine tap over the three broad octaves, for the 300 pt view
//   c3 shear   how steeply omega falls with radius: 0 is nearly rigid, 1 is a
//              tight core dragging a slow rim
[[ stitchable ]] half4 ml_eddy(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float swirl = clamp(c0, 0.0, 1.0);
    float drift = clamp(c1, 0.0, 1.0);
    float grain = clamp(c2, 0.0, 1.0);
    float shear = clamp(c3, 0.0, 1.0);

    // The core wanders. Two incommensurate rates, so it traces a slow open curve
    // that never repeats inside a session and never looks like an orbit.
    float2 core = (0.028 + 0.070 * drift) * float2(sin(T * 0.117), cos(T * 0.091 + 1.7));
    float2 p = uv - core;
    float r = length(p);

    const float RC = 0.17;   // core softening: keeps omega finite at the middle
    const float R0 = 0.25;   // the reference ring the speed is pinned to
    float fall = mix(0.55, 1.45, shear);
    float omega = (0.055 + 0.150 * swirl) * pow((R0 + RC) / (r + RC), fall);

    // Time enters HERE, in the coordinate, and only here.
    //
    // The field is not born unwound. Rendered from a standing start it is a
    // scatter of round blobs for the first ten seconds and only becomes an eddy
    // once the differential rotation has had time to draw them out, and a
    // thinking indicator does not get ten seconds to become itself. So the twist
    // is measured from fourteen seconds before the view appeared. That is not a
    // cheat: fourteen seconds is where winding and renewal balance, so it is the
    // state the field settles into and stays in. Starting there means the first
    // frame is the steady state and every frame after it is too.
    float th = omega * (T + 14.0);
    float cs = cos(th), sn = sin(th);
    float2 q = float2(cs * p.x - sn * p.y, sn * p.x + cs * p.y);

    float f = 3.8 / S;     // about three broad forms across the disc
    float3 dom = float3(q * f, (0.050 + 0.065 * drift) * T);
    float n = ml_fbm3(dom, 3, 2.03, 0.5);
    float g = ml_noise3(dom * 2.85 + float3(11.3, 5.1, 0.0));

    float mass = 0.5 + 1.00 * n + 0.17 * grain * g;
    // A wide, soft threshold. Narrower and the arms grow edges; wider and the
    // whole disc is one grey wash with a turn somewhere inside it.
    float dens = smoothstep(0.36, 0.88, mass);
    dens *= 0.52 + 0.48 * smoothstep(0.02, 0.19, r);   // the core's void

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    float t = 0.045 + 0.60 * dens;
    float hot = smoothstep(0.58, 1.00, dens);
    return ml_write(pal, inkLin, t, hot, 0.88, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 2. Well

// WELL. Pulling inward, toward a deep centre that never fills.
//
// WHY THE POLAR VERSION WAS THROWN AWAY. The first body sampled the noise on a
// cylinder: (cos a, sin a) * ringR for two axes and depth for the third. It is
// seamless, it is cheap, and it is a flower. Sampling a CIRCLE in a noise domain
// gives a function that is periodic in the angle with roughly 2 pi ringR lobes,
// and at any ring count the eye can hold in one glance, six or ten, that is a
// marigold with a black middle. Widening the ring only trades a marigold for a
// pinwheel. The species is not "radiating"; it is PULLING INWARD, and the
// parametrization has to be one where the angle is not a coordinate at all.
//
// SO THE MATERIAL IS SAMPLED IN THE PLANE, at dir * (g(r) + scroll). This is a
// pure radial remap of the pixel's own position: no angle appears anywhere, so
// there is no period to find, and the structure is whatever the noise happens to
// be, drawn out into wisps.
//
//   g(r) = (r + 0.14)^0.60 * F     the remap
//
// The exponent is the whole trick. Because g rises more slowly than r, moving
// one noise cell along a RADIUS takes about five times further on screen than
// moving one cell around the circle does, so every form comes out five times
// longer than it is wide, pointing at the middle. That is the radial draw, and
// it costs one pow. And because g still rises, the circle the sample traces is
// bigger at the rim than at the throat, so there are about fourteen forms around
// the outside and nine at the mouth: streams crowd and merge on the way in,
// which is what falling material does and what stops the count from ever being
// a number the eye can name.
//
// THE SCROLL, AND WHY IT IS CYCLED. Adding a distance to the ring radius walks
// every form inward, and it accelerates because the remap compresses. But that
// distance cannot grow forever: after a minute the forms would be finer than a
// pixel. So it runs on a bounded cycle with TWO layers half a cycle apart,
// cross-faded. Layer j sits at offset (f + j) * CYC with its own slice of the
// noise; at the end of a cycle layer 0 has become exactly what layer 1 was, so
// the recycle happens at the instant the retiring layer's weight is zero and
// nothing on screen jumps. Material arrives at the rim, falls, is consumed, and
// the disc can run all afternoon.
//
// A PRESENCE FLOOR, which the gallery forced. Cut purely on the field, this was
// the dimmest cell in the set and nearly vanished at 76 pt. A well is not a
// place where there is no material; it is a place where material is being taken
// somewhere. So a floor of light rides the convergence and is under the streams
// rather than instead of them: the disc always glows, and the streams are the
// structure inside the glow.
//
// THE THROAT NEVER FILLS. Everything inside r = 0.035 is extinguished, fading in
// over the next eighth of the radius, so the middle is a dark mouth ringed with
// the hottest material in the pack. A well that filled would be a puddle: the
// light has to be spent on the way in rather than arriving.
//
// BARELY SPIRALED. There is a curl, because falling material with any rotation
// at all conserves it, but it is a quarter of what it was: about three quarters
// of a radian of differential twist over a form's whole transit. Enough that the
// wisps lean into the mouth, not enough to be a pinwheel.
//
//   c0 pull        how fast the material falls in
//   c1 depthGlow   how much brighter the material gets as it converges
//   c2 churn       the drain's curl
//   c3 offset      the throat's ECCENTRICITY, not a signed position: 0 is dead
//                  centre, 1 is a third of the radius out, and the direction
//                  turns on its own at a fortieth of a radian a second so no
//                  configuration is ever stuck with a lopsided still frame
[[ stitchable ]] half4 ml_well(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float pull = clamp(c0, 0.0, 1.0);
    float dglow = clamp(c1, 0.0, 1.0);
    float churn = clamp(c2, 0.0, 1.0);
    float offset = clamp(c3, 0.0, 1.0);

    // Pushed further off centre than it was. A dark round hole in the exact
    // middle of a warm ring is an iris, and an indicator that reads as an eye is
    // reading as something. Off centre it reads as a place the material is
    // going, which is what it is.
    float ecc = 0.20 * offset;
    float ea = 0.043 * T + 0.9;
    float2 core = ecc * float2(cos(ea), sin(ea));
    float2 p = uv - core;
    float r = length(p);
    float2 dir = p / max(r, 1e-5);

    // The curl. Differential, so the mouth turns faster than the rim. About a
    // radian and a third of twist between rim and throat over a form's whole
    // transit: enough that the wisps lean into the mouth instead of pointing at
    // it, which is most of what stops a radial draw reading as a starburst, and
    // well short of the eddy's winding, which is that species' whole subject.
    float spin = (0.016 + 0.060 * churn) / (r + 0.26);
    float th = spin * T;
    float cs = cos(th), sn = sin(th);
    float2 d2 = float2(cs * dir.x - sn * dir.y, sn * dir.x + cs * dir.y);

    // THE WARP, AND WHY THE FIRST RADIAL REMAP WAS STILL A FLOWER. Any map of
    // the form dir * h(r) is rotationally equivariant, so a circle on screen is
    // still a CIRCLE in the noise domain and still carries a whole number of
    // lobes around it. Swapping the cylinder for a radial remap changed the
    // radius profile and nothing else; the marigold came straight back, brighter.
    //
    // What breaks it has to be non-equivariant, and one tap of plain Cartesian
    // noise is. Added to the radius, it makes the sampled curve a wobbly circle
    // rather than a circle: forms are encountered at irregular intervals around
    // it, and because the wobble also varies ALONG the radius, no two streams
    // start or end at the same place. Same spacing, same length and same phase
    // are the three things that were making the eye call it a mechanism, and
    // this removes all three for one noise evaluation.
    float warp = ml_noise3(float3(p * (2.2 / S), 51.0 + 0.030 * T));

    // The remap, and the exponent is gone: it is linear now. A compressing power
    // made every form about five times longer than it was wide, and five times
    // is not a wisp, it is a SPOKE. Every spoke then ran the full radius and
    // ended on the same circle, which is a sunburst with a hole punched in it:
    // the second wrong picture this species produced, and a graphic one. Linear
    // in r, with the scroll adding the only radial bias, leaves forms about
    // twice as long as they are wide, which reads as cloud drawn toward
    // something rather than as rays coming out of it.
    const float RC = 0.14;
    float g = (r + RC) * (4.00 / S) + 0.45 * warp;

    // The bounded scroll. See the header: two layers, offsets (f + j) * CYC, the
    // retiring one at zero weight exactly when it is recycled. CYC is short
    // because the scroll is also what stretches the forms, and a long one puts
    // the spokes back.
    const float CYC = 0.60;
    float u = (0.045 + 0.130 * pull) * T / CYC;
    float f = fract(u);
    float kf = floor(u);
    float w = smoothstep(0.0, 1.0, f);
    float zdrift = 0.020 * T;

    float3 dA = float3(d2 * (g + f * CYC),         7.0 + kf * 5.3 + zdrift);
    float3 dB = float3(d2 * (g + (f + 1.0) * CYC), 7.0 + (kf - 1.0) * 5.3 + zdrift);
    float n = mix(ml_fbm3(dB, 3, 2.03, 0.5), ml_fbm3(dA, 3, 2.03, 0.5), w);

    // A broad envelope, one tap, turning slowly, and it is DOMINANT rather than
    // a modulation. Two things need it. At 76 pt the individual wisps are two
    // points wide and the eye can only read the large light and dark, so without
    // a big shape there is nothing at cell size. And a well fed evenly from
    // every direction is a diagram: real infall arrives from somewhere, so whole
    // sectors of this one go nearly dark and others carry most of the material.
    float env = 0.5 + 0.5 * ml_noise3(float3(p * (1.3 / S), 31.0 + 0.045 * T));

    float streams = smoothstep(0.30, 0.92, 0.5 + 1.05 * n);
    float conv = smoothstep(0.48, 0.10, r);          // 0 at the rim, 1 at the mouth
    // The mouth's edge is RAGGED, on the same warp that irregularises the
    // streams. A clean circle of extinction is a punched hole, and every form
    // terminating on it at once is what made the last cut a sunburst.
    float throat = smoothstep(0.025, 0.165 + 0.075 * warp, r);

    float floorLight = 0.20 + 0.22 * conv;           // the presence floor
    float dens = (floorLight + (0.50 + 0.40 * conv) * streams)
               * throat * (0.25 + 1.05 * env);
    // The convergence multiplier is a third of what it first was. Stacked on top
    // of the presence floor it was driving the collar to 0.99 on the rail, and a
    // well whose mouth is white paper is lit from inside, which is the opposite
    // of a well. The floor buys the legibility now; the squeeze only leans on it.
    float lum = 1.0 + (0.30 + 0.60 * dglow) * conv * throat;
    // Kneed at 0.58 rather than clamped: the collar is where this field runs hot
    // and a clamp there draws a hard contour around the mouth.
    float bright = ml_knee(dens * lum * 0.62, 0.58);

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    float t = 0.050 + 0.72 * bright;
    float hot = smoothstep(0.66, 1.00, bright) * 0.70;
    return ml_write(pal, inkLin, t, hot, 0.88, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 3. Tide

// TIDE. A slow wash crossing and returning, with the weight leaning into it.
//
// THE LAW, AND ITS INTEGRAL. The body's speed is a sine and its position is that
// sine's exact integral, which is a cosine, so this field has the same property
// the arc styles have without needing an epoch: sample it at any time at all and
// the water is where the water would be. Nothing accumulates, nothing drifts out
// of phase after ten minutes on screen.
//
//   v(t) = A w sin(w t)      the wash
//   x(t) = -A cos(w t)       where the body is: the integral, exactly
//
// THE SURFACE LEANS WITH THE MASS, not against it. The tilt is proportional to
// x, so it is steepest at the two turns, where the water has finished piling up
// against one side, and flat as the body crosses the middle at full speed. Water
// in a bowl does that. A surface that leaned with the VELOCITY would be steepest
// in the middle of the crossing, which looks like a skew transform and reads as
// a graphic rather than as liquid.
//
// THE SURFACE IS NOT A LINE. It is a soft threshold over a tenth of the disc,
// torn by a travelling one-dimensional fBm that rides along WITH the body (its
// phase carries x), so the ripples belong to the water instead of sliding across
// it. Above it there is a thin mist that decays over a sixth of the disc, which
// is not decoration: it is what keeps the upper cap from being dead ink and
// stops the whole thing reading as a fill gauge.
//
// THE FOAM IS THE ONLY BRIGHTNESS IN THE PACK TIED TO A RHYTHM, and it is tied
// to a physical one. Water throws light off its surface when it is moving and
// goes glassy at the turn, so the crest rides |v| with a floor of 0.30. That is
// the wash being visible in a single frame, not a pulse: the ceiling never
// moves, only the crest, and only because the water is going somewhere.
//
//   c0 reach   how far the body travels
//   c1 lean    how steeply the surface tilts at the turn
//   c2 foam    how much light the moving crest throws
//   c3 period  the there-and-back time, 15 s at 0 down to 6 s at 1
[[ stitchable ]] half4 ml_tide(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float reach = clamp(c0, 0.0, 1.0);
    float lean = clamp(c1, 0.0, 1.0);
    float foam = clamp(c2, 0.0, 1.0);
    float per = clamp(c3, 0.0, 1.0);

    float P = mix(15.0, 6.0, per);
    float w = 6.2831853 / P;
    float ph = w * T;
    float A = 0.16 + 0.30 * reach;
    float pos = -A * cos(ph);              // position: the integral of the speed
    float vel = sin(ph);                   // normalised speed, +1 crossing right
    float sway = pos / max(A, 1e-4);       // -1..1, which side the weight is on

    // The surface. uv.y grows DOWNWARD, so positive `below` is under water.
    // The base level sits a little above centre so the water is most of the
    // disc: a body of light with a lit surface, not a half-filled circle.
    float ripple = 0.030 * S * ml_fbm1((uv.x - pos) * 2.4 / S + 0.35 * T, 3, 5.0);
    float h = -0.080 + 0.55 * lean * sway * uv.x + ripple;
    float below = uv.y - h;

    float f = 4.1 / S;
    // The lean is in the material too: the body shears with depth the way a
    // column of water does when the whole bowl is tipped.
    float3 dom = float3((uv.x - pos - 0.30 * lean * sway * below) * f,
                        uv.y * f * 0.90, 0.050 * T);
    float n = ml_fbm3(dom, 3, 2.03, 0.5);

    float body = smoothstep(-0.045, 0.075, below);
    // The light lives near the surface and is extinguished with depth, Beer's
    // law with a fifth of the disc as its length. The first cut had the mass
    // getting BRIGHTER downward, on the theory that deeper is denser, and the
    // result was an evenly lit half-disc that read as a battery at half charge.
    // Falling off into the dark under the surface is what makes it a wash: the
    // eye follows the lit layer leaning, and the bowl has no bottom to measure.
    float weight = 0.30 + 0.70 * exp(-max(below, 0.0) / 0.20);
    float dens = body * weight * (0.30 + 1.05 * saturate(0.5 + 0.95 * n));

    // The crest, straddling the surface and torn by the same field, so no part
    // of it is ever a rule. Gaussian rather than a band: a band has two edges.
    float edge = below - 0.010 - 0.030 * n;
    float crest = exp(-(edge * edge) / (0.042 * 0.042)) * foam * (0.30 + 0.70 * abs(vel));
    // The air over the water. A sixth of the disc of falloff, so the cap above
    // the surface is dim rather than empty.
    float mist = 0.13 * exp(-max(-below, 0.0) / 0.13);

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    float t = 0.045 + 0.50 * dens + 0.30 * crest + mist;
    float hot = smoothstep(0.60, 1.00, dens) * 0.40 + crest * 0.95;
    return ml_write(pal, inkLin, t, hot, 0.88, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 4. Undertow

// UNDERTOW. Two layers sliding opposite ways, and what is drawn is neither.
//
// THE IDEA, which is the whole species. Two sheets of the same material are
// advected in opposite directions across the disc. Adding them together would
// give a wash going nowhere. Instead the picture is the SEAM: the set of places
// where the two sheets happen to read the same value. That set is a braid of
// filaments, it is dense where the two are similar and sparse where they are
// not, and it moves in NEITHER direction, because it belongs to both sheets at
// once. Watch it and you cannot say which way it is going, which is exactly what
// it feels like to stand in one.
//
//   d = na - nb
//   seam = w^2 / (w^2 + d^2)
//
// A Lorentzian rather than a threshold on |d|. It has no edge at any width: it
// falls off forever instead of stopping, which is what an isoline of a smooth
// field should look like when it is made of liquid rather than drawn with a pen.
// `contrast` sets w, so turning it up narrows the braid and turning it down
// broadens it into a haze, and neither end has a hard value in it.
//
// THE BRAID IS GATED BY THE OVERLAP of the two layer masks, 4 m (1 - m), which
// is 1 exactly on the interface and 0 where one layer has the frame to itself.
// So the disc reads as mass above, mass below, and structure born in the band
// between them: three things, which is one more than a shear usually gives you
// and the reason this holds up at 300 pt.
//
// THE SLIP IS SLOW. Thirty two thousandths of a frame width a second each way at
// the default, so a feature takes most of half a minute to cross. Faster reads
// as scrolling, and scrolling is the one thing a thinking indicator must never
// look like.
//
//   c0 contrast   how tight the seam is against how present the veil is
//   c1 slip       the differential speed of the two sheets
//   c2 veil       how much of the two sheets themselves is visible at all
//   c3 bias       where the interface sits: 0.5 through the centre, 0 and 1 a
//                 quarter of the disc up or down, and it always breathes a
//                 little on a ninety second period so it is never a rule
[[ stitchable ]] half4 ml_undertow(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float contrast = clamp(c0, 0.0, 1.0);
    float slip = clamp(c1, 0.0, 1.0);
    float veil = clamp(c2, 0.0, 1.0);
    float bias = clamp(c3, 0.0, 1.0);

    float iface = 0.52 * (bias - 0.5) + 0.030 * sin(T * 0.071);
    float sfrac = (uv.y - iface) / 0.24;
    float mUp = 1.0 - smoothstep(-1.0, 1.0, sfrac);
    float overlap = 4.0 * mUp * (1.0 - mUp);

    float u = 0.012 + 0.042 * slip;
    float f = 3.6 / S;
    // Two sheets of the same material at slightly different scales and different
    // corners of the noise domain, so they are two sheets and not one sheet
    // sampled twice.
    float3 qa = float3((uv.x - u * T) * f,        uv.y * f * 1.00,  2.0 + 0.040 * T);
    float3 qb = float3((uv.x + u * T) * f * 1.07, uv.y * f * 0.92, 23.0 + 0.036 * T);
    float na = ml_fbm3(qa, 3, 2.03, 0.5);
    float nb = ml_fbm3(qb, 3, 2.03, 0.5);

    float d = na - nb;
    // The width is generous, and that is the correction that made this liquid.
    // The first cut ran a tenth of this and drew hairlines: bright wires
    // crossing a dark disc, which is lightning, not water. na - nb has a spread
    // of about half a unit, so a width of 0.16 makes the seam a BAND about a
    // third of that spread wide, which is a braid of soft channels rather than a
    // wire diagram. Contrast still tightens it, but it can no longer reach a
    // width where the material has an edge.
    float wid = 0.075 + 0.170 * (1.0 - contrast);
    float seam = (wid * wid) / (wid * wid + d * d);

    float base = mUp * (0.5 + 0.95 * na) + (1.0 - mUp) * (0.5 + 0.95 * nb);
    base = smoothstep(0.22, 0.95, base);

    float braid = seam * overlap * (0.30 + 0.55 * contrast);

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    // The two sheets carry more of the picture than they did, so the braid has
    // mass on both sides of it to be born between rather than a void.
    float t = 0.045 + (0.20 + 0.42 * veil) * base + 0.34 * braid;
    // THE WALK IS CAPPED BELOW THE PALE STOP, and this is the pour pack's
    // pv_tint lesson arriving a second time. Of the six species this one keeps
    // the most of its area near the tone, so the braid's peaks were the only
    // places in the pack routinely crossing 0.78 into the specular segment,
    // where the rail halves its chroma on the way to a pale highlight. The
    // result was a grey-white tangle sitting next to five warm neighbours in the
    // gallery. Kneed rather than clamped, so the top of the range compresses
    // toward 0.77 instead of flattening onto it and drawing a contour.
    t = 0.77 * ml_knee(t / 0.77, 0.70);
    float hot = braid * 0.50 + smoothstep(0.74, 1.00, base) * 0.18;
    // Emitting at 0.80, not the pack's usual 0.88: on a field already sitting at
    // the tone, pale light does not read as hotter amber, it reads as grey.
    return ml_write(pal, inkLin, t, hot, 0.80, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 5. Meander

// MEANDER. One bright channel wandering through dark ground. The path is the
// thought.
//
// THE CENTRELINE is a one-dimensional fBm in x, drifting slowly in its own
// argument so the river re-cuts itself over a minute or so rather than holding a
// shape. Three taps of it a pixel: the value, and one on each side. The two
// neighbours are there for the SLOPE, and the slope earns its cost. Distance to
// a curve measured straight down the y axis is not distance to the curve; it is
// distance divided by the cosine of the bank angle, so a channel drawn that way
// fattens wherever the river turns, which is precisely where a real one narrows.
// Dividing by sqrt(1 + slope^2) is the correction, and without it the meander
// reads as a fat lazy ribbon instead of as water finding a way through.
//
// THE LIGHT INSIDE IT TRAVELS. The channel's own material is a field sampled in
// channel coordinates (along the river, across it) and advected along, so the
// bright and dim stretches slide downstream while the banks stay put. That is
// the difference between a river and a drawn line: the line is where the water
// is, the water is not the line.
//
// TWO GAUSSIANS, not one, and this is the pack's only real spatial bloom.
// exp(-1.55 u^2) is the water; exp(-0.30 u^2) is its light in the air above it,
// two and a quarter times as wide and an eighth as bright. Both are closed form,
// so the halo costs two exponentials rather than eleven taps of the field.
//
// THE BANKS ARE CUT DARK, which is the thing that makes it read as a channel
// rather than as a glowing stroke. A dim ring just outside the water pushes the
// ground back toward ink, so the river sits IN something. Ground that simply got
// darker with distance would read as a vignette; a lip at a fixed distance from
// the water reads as an edge the water made.
//
//   c0 width    the channel's half width
//   c1 wander   how far the path strays from straight
//   c2 bank     how deep the cut on either side is
//   c3 flow     how fast the light travels down it
[[ stitchable ]] half4 ml_meander(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float width = clamp(c0, 0.0, 1.0);
    float wander = clamp(c1, 0.0, 1.0);
    float bank = clamp(c2, 0.0, 1.0);
    float flow = clamp(c3, 0.0, 1.0);

    float xa = uv.x / S;
    float pth = 0.026 * T;                    // the river re-cuts itself, slowly
    const float PF = 1.15;                    // the path's pitch, in xa
    const float DX = 0.055;                   // the slope's half step, in xa

    // THE WANDER IS DOMAIN DRIFT, NOT JITTER, and that distinction is the whole
    // fix. Three fBm octaves at a pitch of 3.2 gave the disc three bends with
    // kinks between them, and three bends with kinks is a seismograph trace.
    // Read as an EQ meter it is not merely wrong, it is a banned shape.
    //
    // So the path is ONE smooth value-noise arc at a pitch of 1.15, which is
    // about one cell across the whole disc: a single broad curve, sometimes a C,
    // sometimes a lazy S, never a zigzag. The second term is a quarter-weight
    // whisper at twice the pitch, enough that the arc is not a parabola. All the
    // CHANGE comes from `pth` sliding the domain underneath at a fortieth of a
    // cell a second, so the river re-cuts itself over about forty seconds
    // without ever moving fast enough to watch. Slow domain drift, not per-x
    // detail: the same amount of life, none of the graph.
    float w0 = ml_vnoise1(xa * PF + pth, 7.0)
             + 0.24 * ml_vnoise1(xa * PF * 2.3 + pth * 1.4, 23.0);
    float wA = ml_vnoise1((xa - DX) * PF + pth, 7.0)
             + 0.24 * ml_vnoise1((xa - DX) * PF * 2.3 + pth * 1.4, 23.0);
    float wB = ml_vnoise1((xa + DX) * PF + pth, 7.0)
             + 0.24 * ml_vnoise1((xa + DX) * PF * 2.3 + pth * 1.4, 23.0);

    float amp = 0.13 + 0.22 * wander;
    float yc = amp * w0;
    float slope = amp * (wB - wA) / (2.0 * DX) / S;
    float dist = (uv.y - yc) / sqrt(1.0 + slope * slope);

    // The width breathes along the length. A channel of constant width is a
    // pipe; rivers pool and pinch. The pitch of the breathing came down with the
    // path's, for the same reason: at 3.2 the pinches were close enough together
    // to read as teeth.
    float wv = (0.055 + 0.085 * width) * S;
    wv *= 0.80 + 0.36 * (0.5 + 0.5 * ml_vnoise1(xa * 1.5 + 3.3, 19.0));
    float uu = dist / max(wv, 1e-4);

    float travel = (0.20 + 0.55 * flow) * T;
    // The cross-channel coordinate is CLAMPED before it goes into the water
    // field, and that clamp is not tidiness. uu grows without bound away from
    // the centreline, so an unclamped sample makes the width modulation below a
    // function of how far out you are, and the channel grows feathers: vertical
    // streaks combed out of it at every bend. Two channel widths of cross
    // variation is all the water has; past that it is the same water.
    float3 qf = float3(xa * 3.4 - travel, clamp(uu, -2.0, 2.0) * 0.42, 4.0 + 0.030 * T);
    float water = saturate(0.45 + 0.95 * ml_fbm3(qf, 3, 2.03, 0.5));

    // The water swells and pinches the channel it is in, so the SILHOUETTE
    // moves with the flow and not just the brightness inside a fixed outline.
    // Without this the meander is a stroke with a texture painted on it, which
    // is what the first render was and what a drawn line would have been. The
    // range is gentler than it was: a channel whose width swings by half its own
    // size grows vertical combs where the path is steep.
    float k = uu / (0.78 + 0.44 * water);
    float g1 = exp(-1.55 * k * k);            // the water
    float g2 = exp(-0.30 * k * k);            // its light in the air

    // The ground. Two octaves is enough: it is meant to have form at 300 pt and
    // to be invisible at 20, and a third octave only buys noise at both.
    float3 qm = float3(uv.x * 2.6 / S, uv.y * 2.6 / S, 30.0 + 0.045 * T);
    float ground = smoothstep(0.25, 0.95, 0.5 + 1.0 * ml_fbm3(qm, 2, 2.03, 0.5));

    // THE BANKS ARE SHOULDERS, NOT A RING. The first cut used a tight Gaussian
    // at a fixed distance and drew a dark outline around the water, which is a
    // stroke with a keyline: exactly the graphic reading this style has to lose.
    // A standard deviation of about one whole channel width instead makes the
    // ground fall away either side of the river and come back, which is what a
    // cut bank looks like from above and has no edge anywhere in it.
    float lip = abs(uu) - 1.90;
    float cut = 1.0 - 0.55 * bank * exp(-0.42 * lip * lip);

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    float t = 0.045 + 0.20 * ground * cut + g1 * (0.12 + 0.38 * water) + g2 * (0.05 + 0.07 * water);
    float hot = g1 * (0.20 + 0.80 * water) * 0.70;
    return ml_write(pal, inkLin, t, hot, 0.88, glow, ml_bowl(uv), position * pixelScale);
}

// MARK: - 6. Confluence

/// THE JOIN LAW. The pv_exhale_law pattern, and the same argument for it: state
/// the MOTION as a law and take the position as that law's exact integral, so no
/// frame has to remember the last one. Sample at any t at all, from a screenshot
/// rig, a scrubbed slider or an app resumed from the background, and the flows
/// are exactly where the animation would have put them.
///
///   v(tau) = hold + (1 - hold) e^(-k tau),   k = 3 / joinTime
///   D(tau) = hold tau + (1 - hold) (1 - e^(-k tau)) / k
///
/// k = 3 / joinTime rather than 1 / joinTime so the dial means what it says: at
/// tau = joinTime the approach is within five per cent of the hold, which is the
/// instant a person would call it joined.
///
/// HOLD IS 0.16, not the exhale's 0.055, and the difference is the species. A
/// breath that has been let out is nearly still and should be. A river that has
/// taken in another river is a bigger river: it is going somewhere at the end,
/// so the rest state here keeps about a sixth of its arrival speed forever, and
/// the joined channel's light still moves down it. Returns (v, D, e), where e is
/// the fraction of the approach still to run.
static inline float3 ml_join_law(float tau, float joinTime) {
    const float HOLD = 0.16;
    float E = max(joinTime, 0.50);
    float k = 3.0 / E;
    float e = exp(-k * max(tau, 0.0));
    float v = HOLD + (1.0 - HOLD) * e;
    float D = HOLD * max(tau, 0.0) + (1.0 - HOLD) * (1.0 - e) / k;
    return float3(v, D, e);
}

// CONFLUENCE. Two flows finding each other, and joined is the rest state.
//
// THE ARC. Everything that arrives rides `e`, the fraction of the approach still
// to run, and everything that keeps going rides `D`, the distance travelled.
// Three things arrive:
//
//   the separation    the arms start (0.055 + 0.15 approach) apart at the
//                     meeting and close to 0.020, which is not zero. Two rivers
//                     that have joined still have a line between them for a
//                     while; a separation that went to zero would make the
//                     rest state one channel with no memory of being two, and
//                     the memory is the point.
//   the meeting       the junction slides upstream, from a quarter of the disc
//                     right of centre to just left of it. At birth the disc is
//                     mostly two arms with a join in the corner; at rest it is
//                     mostly one flow with a fork at its left edge. That is the
//                     arc a person actually reads.
//   the tempo         the light down the channel starts at six times its
//                     resting speed and settles. The arrival is legible in a
//                     SINGLE FRAME, not only in motion: photograph it at one
//                     second and at twelve and the two are different pictures,
//                     not the same picture at two offsets.
//
// One thing does not arrive: D keeps growing at the hold rate forever, so the
// joined river is still a river a minute later. Settled is a whisper of motion,
// never a freeze.
//
// THE BRAID IS FREE. Each arm carries its own small wander on its own noise
// lane. Downstream of the junction both centrelines land on the same axis, so
// what is left of them is two wanders of about a thirtieth of the disc crossing
// and re-crossing inside one channel. Nothing draws a braid; the braid is what
// two paths that have agreed on a direction but not on a route do.
//
// THE TWO CHANNELS COMBINE AS A + B - AB, not A + B. Where they coincide, a sum
// counts the same water twice and the join is a hot bar exactly where the
// picture should be calmest. The soft union caps at one and leaves the junction
// looking like more water rather than like more light.
//
//   c0 approach   how far apart the flows start
//   c1 mingle     how much the two waters interleave once joined
//   c2 shimmer    fine surface texture travelling with the flow
//   c3 angle      the fork's spread, from nearly parallel to a wide Y
[[ stitchable ]] half4 ml_confluence(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch
) {
    float2 uv = ml_uv(position, size);
    float S = max(formScale, 0.10);
    float T = time * max(speed, 0.0);

    float approach = clamp(c0, 0.0, 1.0);
    float mingle = clamp(c1, 0.0, 1.0);
    float shimmer = clamp(c2, 0.0, 1.0);
    float angleK = clamp(c3, 0.0, 1.0);

    // The law runs on real seconds: five is the time a person waits for two
    // things to become one thing without wondering whether it is stuck.
    float tau = max(time - epoch, 0.0);
    float3 law = ml_join_law(tau, 5.0);
    float e = law.z;
    float travel = law.y * 0.85 * max(speed, 0.0);

    // THE JOINED FLOW LEAVES ALONG ITS OWN HEADING. Built on the frame's x axis
    // this style settled into a horizontal band, which is a silhouette three
    // other species in the roster already own, and a confluence that ends up
    // looking like everything else has no identity left. So the whole figure is
    // constructed in a rotated frame: `o` is the outflow's heading, a quarter
    // radian below horizontal, and the junction sits up and back from the middle
    // of the disc. The composition is then lopsided in both axes at every moment
    // of the arc, which is the only reliable way a circle full of soft light
    // stays recognisable at cell size.
    const float OUT = 0.42;
    float2 o = float2(cos(OUT), sin(OUT));
    float2 nrm = float2(-o.y, o.x);
    float2 qv = uv - float2(-0.10, -0.07);
    float sAx = dot(qv, o);                      // along the outflow
    float nAx = dot(qv, nrm);                    // across it

    // The FORK ITSELF closes, and that is what makes the arc legible. The first
    // cut moved only the separation at the meeting and the meeting's position,
    // and both are small next to the arms' spread, so birth and rest were the
    // same picture a few points apart. Swinging the spread means the shape goes
    // from a wide Y to a single flow with a taper behind it. It closes to 45 per
    // cent and not to nothing: joined is the rest state, but a confluence that
    // forgets it was ever two rivers is just a river.
    float spread = mix(0.14, 0.55, angleK) * (0.45 + 0.55 * e);
    float sep = 0.018 + (0.030 + 0.120 * approach) * e;
    float sj = 0.22 * e;                         // the meeting, sliding upstream
    float conv = 1.0 - smoothstep(sj - 0.26, sj + 0.14, sAx);
    float su = max(sj - sAx, 0.0);               // how far upstream of it we are

    // The arms wander. Straight arms are a glyph; the wander is under one
    // channel width so downstream the two paths weave INSIDE the joined channel
    // instead of separating back out into two.
    // The pitch is 4.5 because across a disc 0.9 wide anything lower is a
    // constant offset wearing a noise function's name, and two arms offset by a
    // constant are two straight lines.
    float wig = 0.038 * S;
    float armN = (sep + spread * su) * conv;
    float cA = -armN + wig * ml_fbm1(sAx * 4.5 / S - travel * 0.55, 2, 13.0);
    float cB =  armN + wig * ml_fbm1(sAx * 4.5 / S - travel * 0.55, 2, 47.0);

    // The joined channel is wider than either arm, because it is carrying both,
    // and each arm breathes on its own lane. The two are NOT twins: B runs about
    // a fifth wider, because two identical inflows read as a mirrored diagram
    // and no two rivers are the same size.
    float wBase = 0.040 * S * (1.0 + 0.50 * (1.0 - conv));
    float wvA = wBase * (0.90 + 0.44 * (0.5 + 0.5 * ml_vnoise1(sAx * 2.6 / S - travel * 0.5, 63.0)));
    float wvB = wBase * 1.18
              * (0.90 + 0.44 * (0.5 + 0.5 * ml_vnoise1(sAx * 2.6 / S - travel * 0.5 + 5.7, 71.0)));
    float ua = (nAx - cA) / max(wvA, 1e-4);
    float ub = (nAx - cB) / max(wvB, 1e-4);

    // Clamped across, for the meander's reason: an unbounded cross coordinate
    // combs feathers out of the channel wherever it turns. The pitch along is
    // 4.8 and not 7: at 7 the water broke into a row of separate bright beads
    // down the channel, and this family does not do dots under any name.
    float3 qA = float3(sAx * 4.8 / S - travel, clamp(ua, -2.0, 2.0) * 0.45,  3.0);
    float3 qB = float3(sAx * 4.8 / S - travel, clamp(ub, -2.0, 2.0) * 0.45, 26.0);
    float wA = saturate(0.45 + 0.95 * ml_fbm3(qA, 3, 2.03, 0.5));
    float wB = saturate(0.45 + 0.95 * ml_fbm3(qB, 3, 2.03, 0.5));

    // Each arm's own water swells and pinches it, the meander's correction for
    // the same failure: a channel whose outline never moves is a stroke.
    float ka = ua / (0.78 + 0.44 * wA), kb = ub / (0.78 + 0.44 * wB);
    float gA1 = exp(-1.45 * ka * ka), gA2 = exp(-0.28 * ka * ka);
    float gB1 = exp(-1.45 * kb * kb), gB2 = exp(-0.28 * kb * kb);

    // The lacing. A slow scalar travelling downstream decides which water is on
    // top at each point along the joined channel, and it only applies where the
    // channel IS joined: upstream each arm is entirely its own.
    float lace = clamp(0.5 + 0.55 * ml_vnoise1(sAx * 4.2 / S - travel * 0.8, 41.0), 0.0, 1.0);
    float sA = mix(0.5, mix(0.5, lace, mingle), 1.0 - conv);

    float lightA = gA1 * (0.14 + 0.46 * wA) * (0.70 + 0.60 * sA);
    float lightB = gB1 * (0.14 + 0.46 * wB) * (0.70 + 0.60 * (1.0 - sA));
    float chan = lightA + lightB - lightA * lightB;      // soft union, not a sum

    // THE MEETING IS ALIVE. The shimmer used to be spread down the whole channel,
    // where it was a texture nobody could locate. Gathered into the junction it
    // is the one place in the composition where something is happening: two
    // waters at different speeds arriving at the same water and turning over. It
    // travels with the flow, so it reads as disturbance and not as glitter, and
    // it walks upstream with `sj` as the arc runs.
    float ds = sAx - sj;
    float meet = exp(-(ds * ds) / (0.085 * 0.085)) * exp(-(nAx * nAx) / (0.075 * 0.075));
    float shN = ml_noise3(float3(sAx * 7.0 / S - travel * 1.9, nAx * 7.0 / S, 0.40 * travel));
    float churnUp = (0.10 + 0.30 * shimmer) * meet * (0.45 + 0.55 * (0.5 + 0.5 * shN));

    float3 qh = float3(uv.x * 2.4 / S, uv.y * 2.4 / S, 40.0 + 0.035 * T);
    float haze = smoothstep(0.28, 0.96, 0.5 + 1.0 * ml_fbm3(qh, 2, 2.03, 0.5));

    MLPalette pal = ml_palette(inkColor, toneColor, hueShift, depth);
    float3 inkLin = ml_srgb_to_linear(float3(inkColor.rgb));

    float t = 0.045 + 0.12 * haze + 0.58 * chan + 0.05 * (gA2 + gB2) + churnUp;
    float hot = chan * chan * 0.90 + churnUp * 0.80;
    return ml_write(pal, inkLin, t, hot, 0.88, glow, ml_bowl(uv), position * pixelScale);
}
