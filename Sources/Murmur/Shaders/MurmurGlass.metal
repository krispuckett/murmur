// The Glass pack. The hero collection, and the answer to the verdict that killed
// the first forty-eight: "they just don't feel high quality yet."
//
// THE LESSON OF THE REFERENCE CLASS. The Siri and ChatGPT voice orbs do not
// differentiate by silhouette. Every one of them is the same soft volumetric
// glass body; what changes between them is what is happening INSIDE. The first
// forty-eight species went the other way -- each one invented its own shape, and
// forty-eight shapes is a grid of experiments rather than a collection. So this
// family has exactly ONE body, written once and carefully below, and twelve
// interiors. The body is the product. The heroes are what it is thinking about.
//
//   mh_aura     two or three wide soft ribbons of coloured light drifting
//               INSIDE the volume, crossing each other at different depths.
//   mh_droplet  the deformation hero: a zero-g liquid sphere wobbling, breathing
//               with voice, nearly clear around a soft luminous core.
//   mh_limn     near-dark glass whose EDGE is alive: a travelling arc of rim
//               light with a soft tail, never a full even ring.
//   mh_comet    one bright point on a tilted three-dimensional orbit inside,
//               trailing light that curves with the volume.
//
// WHAT THE BODY KIT IS, and why each part of it is there. Seven things separate a
// glass presence from a painted disc, and a species that skips any one of them
// looks like a sticker no matter how good its interior is:
//
//   1. A DEFORMED SDF SPHERE. mh_deform sums three low-order modes -- sines of
//      the dot product with three slowly rotating axes, wavenumbers 1.7, 2.6 and
//      3.4, so roughly one and a half to three lobes across the body. Low order
//      matters: a high-frequency surface is a golf ball, and the eye reads it as
//      texture rather than as a soft body that is slightly out of round. Every
//      hero carries at least a whisper of it (0.022) because a mathematically
//      perfect sphere is the single most obvious tell that something was drawn
//      by a formula. Droplet turns it to 0.064, and gains its SHADING up
//      further still, which is what a body allowed to look liquid needs.
//
//   2. A REAL INTERIOR. Five taps along the view ray between the entry point and
//      the exit, sampling a THREE-DIMENSIONAL field, accumulated front to back
//      with transmittance so near content occludes far. This is the whole
//      argument of the family: interior content that parallaxes as the body
//      turns cannot be faked by painting on a disc, and the eye knows within
//      about a second which one it is looking at.
//
//   3. REFRACTION AT ENTRY. The ray does not go straight in. mh_refract bends it
//      toward the normal by Snell's law at a gentle 1.20 index, which does
//      nothing at the centre (the normal faces the viewer, so there is no angle
//      to bend) and everything at the limb, where it drags the ray across the
//      body and compresses the interior into the edge. That compression is what
//      makes a sphere look like it is FULL of something. Without it the interior
//      reads as a decal even with the depth march intact -- this was the single
//      biggest step up in the whole file.
//
//   4. A FRESNEL RIM THAT IS NOT A RING. Edge light rises as pow(1 - N.z, 3.9),
//      so it lives in the outer eighth of the body, and it is then weighted by
//      direction: brighter on the side away from the key. An even rim is a
//      stroked circle; an uneven one is a body in a room. It rides the DEFORMED
//      normal, so on droplet the rim traces the wobble.
//
//   5. ONE SPECULAR AND A CONTACT GLOW. Two lobes -- a tight one at 96 and a
//      broad sheen at 4 -- from one key up and to the left that drifts a few
//      degrees over half a minute, plus a barely-there bloom outside the
//      silhouette that pools slightly beneath. The specular is what reaches the
//      rail's cream stop; per the value hierarchy, a cell whose brightest pixel
//      is rust has failed, and on a glass body the highlight is the honest place
//      for the brightest pixel to be.
//
//   6. ABSORPTION. MH_EXT gives the glass a base extinction per unit of path, so
//      the far side of the body is genuinely dimmer than the near side. It is
//      one constant and it bought more depth than any other line in the file: it
//      is what makes a ribbon passing behind the middle read as passing BEHIND
//      rather than merely crossing.
//
//   7. THE FRESNEL SPLIT. mh_transmit weights the interior by how square the
//      view is to the surface, so near the limb almost nothing gets through.
//      That is what puts a real boundary between a bright reflective rim and the
//      content behind it, which is the contrast the reference orbs have and
//      which no amount of rim brightness produces on its own. It also kills the
//      inverted ghost a sphere lenses out of its own interior near the limb --
//      on comet that ghost had been reading as a second comet.
//
// THE MOTION LAW. Nothing here ticks. Every travelling phase goes through
// mh_drift, which is a rate plus the integral of a slow sinusoidal modulation of
// that rate: the closed form is theta = w*t + (k*w/w2)*sin(w2*t), whose
// derivative is w*(1 + k*cos(w2*t)) and is therefore strictly positive for
// k < 1 -- it speeds up and slows down and never stops or reverses. Every
// breath goes through mh_breath, which sums two periods (9.4 s and 14.7 s) that
// share no multiple the eye can find, so the body is always mid-breath and never
// at the top or bottom of a cycle you could count. Each hero's phases are given
// different lanes so no two of its motions agree, which is the difference
// between a presence and a mechanism.
//
// THE HUE SPREAD, and why the rail got its one extension. The reference orbs let
// two or three neighbouring hues interplay inside the glass, and that is a large
// part of why they look expensive. The hard rule is one hue family per
// configuration and the rail exists to enforce it, so the extension is made
// where it cannot go wrong: mh_shade walks the copied three-segment rail exactly
// as before and then ROTATES the resulting OKLAB chroma vector by an angle. L
// and C are untouched, so a spread colour is the same lightness and the same
// saturation as the anchor -- it cannot go muddy, because muddy is what happens
// when chroma is traded for hue. The cap is 0.50 radians, about 29 degrees each
// way: amber to gold on one side and amber to ember on the other. At hue = 0 the
// rotation is the identity and the rail is bit-for-bit the copied one. `spread`
// is c3 on every hero and each spends it on the axis that means something in its
// own physics: aura on which ribbon, comet on the age of the trail, limn on the
// distance behind the arc's head, droplet on depth through the body.
//
// SIZE. Three mounts, and the middle one is not the design target: an 18 pt
// inline field, a 46 pt chip, a 120 pt voice stage. mh_small is the dial and
// every hero spends it the same way -- STRUCTURE COUNTS DOWN, STROKES THICKEN,
// FINE FREQUENCIES SWITCH OFF. At 18 pt aura is two thick ribbons, droplet is a
// wobbling body around one big core, limn is a broad comma of rim light, and
// comet is a spark circling on a wider orbit. What survives is one bold gesture.
// At 120 pt the third ribbon, the granulation, the interior hint and the fine
// trail all come back, and they are what makes the large mount worth watching.
//
// THE CLIP IS A HARD BOUNDARY AND THE BODY RESPECTS IT. The view clips to a
// circle at length(uv) = 0.5. The body sits at MH_R = 0.300 with its
// displacement capped at 8.5 per cent and, on droplet, a voice swell capped at
// 5 per cent on top of that, so the worst case silhouette is 0.339 and the
// containment does not begin to fall until 0.36. The contact glow is allowed to
// run into that falloff because it is a soft gradient meeting another soft
// gradient; the BODY never is, because a sliced glass sphere is the one failure
// nobody would forgive. The body's radius is deliberately NOT driven by
// formScale for the same reason: the silhouette is this family's identity and it
// is not a dial. formScale scales the interior forms, which is where it means
// something anyway.
//
// EPOCH IS IGNORED. None of the twelve is an arc species: a glass presence is
// always on, it does not arrive and settle. Every hero is complete, alive and
// worth a screenshot at level = 0, activity = 0 and state = idle, because that
// is the frame a gallery catches and the state a silent app sits in for hours.
//
// COPIED HELPERS. Cross-file Metal linkage is not guaranteed, so the kit is
// copied out of FieldLab.metal and FieldPackPour.metal (by way of
// MurmurPresence.metal, this pack's conventions exemplar) VERBATIM under an mh_
// prefix. Copied, unchanged except for the name:
//
//   mh_hash, mh_grad3, mh_noise3,
//   mh_srgb_to_linear, mh_linear_to_srgb, mh_linear_to_oklab,
//   mh_oklab_to_linear, mh_lch, MHPalette, mh_palette,
//   mh_out, mh_knee, mh_tier, mh_lit, mh_aa, mh_spin,
//   mh_live, mh_small, mh_state
//
// Their comments come with them: the reasoning is the part worth carrying.
// mh_shade is the copied rail plus the documented hue rotation above, and
// mh_containment is the copied one with a tighter span, because this family's
// silhouette is a hard-edged body rather than a field that dissolves on its own.
// The derivative-carrying noise, the fBm and the settle law are NOT copied:
// this pack's surfaces are closed-form so their slopes are exact and free, its
// interior haze wants one octave rather than four, and nothing here honours
// epoch. Dead code behind a prefix is still dead code.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - The copied kit
//
// Everything in this section is FieldLab.metal's, FieldPackPour.metal's or
// MurmurPresence.metal's, verbatim, renamed. The two exceptions say so.

/// An integer avalanche. Lattice coordinates in, well-mixed bits out. A sine
/// hash was the other option and it drifts into visible repeats once the domain
/// gets large, which the long previews here would find.
static inline uint mh_hash(uint3 v) {
    uint h = v.x * 1597334673u ^ v.y * 3812015801u ^ v.z * 2798796415u;
    h ^= h >> 15; h *= 2246822519u;
    h ^= h >> 13; h *= 3266489917u;
    h ^= h >> 16;
    return h;
}

/// A unit vector distributed uniformly on the sphere, from one lattice cell.
/// Uniform matters: gradients bunched near the poles put a grain in the field
/// that reads as a weave once the octaves stack.
static inline float3 mh_grad3(int3 c) {
    uint h = mh_hash(uint3(c + 4096));
    float z = fma(float(h & 0xFFFFu), 2.0 / 65535.0, -1.0);
    float a = float((h >> 16) & 0xFFFFu) * (6.28318530718 / 65536.0);
    float r = sqrt(max(0.0, 1.0 - z * z));
    return float3(r * cos(a), r * sin(a), z);
}

/// The value alone, for the places that never ask what the slope is.
static float mh_noise3(float3 p) {
    float3 i = floor(p);
    float3 f = p - i;
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    int3 c = int3(i);

    float va = dot(mh_grad3(c + int3(0, 0, 0)), f - float3(0.0, 0.0, 0.0));
    float vb = dot(mh_grad3(c + int3(1, 0, 0)), f - float3(1.0, 0.0, 0.0));
    float vc = dot(mh_grad3(c + int3(0, 1, 0)), f - float3(0.0, 1.0, 0.0));
    float vd = dot(mh_grad3(c + int3(1, 1, 0)), f - float3(1.0, 1.0, 0.0));
    float ve = dot(mh_grad3(c + int3(0, 0, 1)), f - float3(0.0, 0.0, 1.0));
    float vf = dot(mh_grad3(c + int3(1, 0, 1)), f - float3(1.0, 0.0, 1.0));
    float vg = dot(mh_grad3(c + int3(0, 1, 1)), f - float3(0.0, 1.0, 1.0));
    float vh = dot(mh_grad3(c + int3(1, 1, 1)), f - float3(1.0, 1.0, 1.0));

    return mix(mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y),
               mix(mix(ve, vf, u.x), mix(vg, vh, u.x), u.y), u.z);
}

static inline float3 mh_srgb_to_linear(float3 c) {
    c = max(c, 0.0);
    return select(c * (1.0 / 12.92), pow((c + 0.055) * (1.0 / 1.055), 2.4), c > 0.04045);
}

static inline float3 mh_linear_to_srgb(float3 c) {
    c = max(c, 0.0);
    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c > 0.0031308);
}

static inline float3 mh_linear_to_oklab(float3 c) {
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

static inline float3 mh_oklab_to_linear(float3 lab) {
    float l_ = lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z;
    float m_ = lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z;
    float s_ = lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z;
    float l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    return float3( 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                  -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                  -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s);
}

/// Lightness, chroma, hue back into OKLAB's rectangular form.
static inline float3 mh_lch(float L, float C, float h) {
    return float3(L, C * cos(h), C * sin(h));
}

/// Four OKLAB stops built from one anchor: the tone the indicator wears.
/// Ordered dark to bright, and never more than one hue family wide.
struct MHPalette { float3 s0, s1, s2, s3; };

/// s0 is the ink the whole app sits on, so a field at zero dissolves into the
/// screen with no seam. s1 is a deep shadow that KEEPS the tone's hue at half
/// its chroma, which is what stops the dark end going grey. s2 is the tone. s3
/// is a pale specular a few degrees warmer, because light that has passed
/// through anything comes out warmer than the thing it lit.
/// `depth` opens the range from both ends without letting the hue wander.
static MHPalette mh_palette(half4 inkColor, half4 toneColor, float hueShift, float depth) {
    float3 ink = mh_linear_to_oklab(mh_srgb_to_linear(float3(inkColor.rgb)));
    float3 tone = mh_linear_to_oklab(mh_srgb_to_linear(float3(toneColor.rgb)));

    float L = tone.x;
    float C = length(tone.yz);
    float h = atan2(tone.z, tone.y) + hueShift;
    float d = clamp(depth, 0.30, 2.00);

    // The shadow shifts WARM as it darkens, roughly twenty degrees of hue
    // toward ember, and keeps most of its chroma rather than draining to grey.
    // Both of those are the difference between a deep amber and mud: a straight
    // desaturating fall from gold to ink passes through olive, and olive is what
    // the first cut of every one of these fields looked like.
    MHPalette p;
    p.s0 = ink;
    p.s1 = mh_lch(mix(ink.x, L, 0.30 / d), C * (0.52 + 0.10 * d), h - 0.35);
    p.s2 = mh_lch(L, C, h);
    p.s3 = mh_lch(min(L * (1.20 + 0.12 * d), 0.93), C * 0.55, h + 0.10);
    return p;
}

/// Walk the family. Three segments, each eased so its ends are flat, which
/// makes the joins C1: no kink shows up as a contour line in a smooth field.
/// Returns LINEAR light; mh_out does the encoding.
///
/// THE ONE EXTENSION, and the header argues for it at length: `hue` rotates the
/// walked colour's OKLAB chroma vector before it is converted, which moves the
/// hue while holding lightness and chroma exactly. That is the safe axis. The
/// unsafe one is trading chroma for hue, which is how a warm palette turns to
/// mud, and this cannot do it. At hue = 0 the rotation is the identity and this
/// is the copied function unchanged, which is the property that lets every
/// non-spread pixel in the pack stay on the house rail.
static float3 mh_shade(MHPalette p, float t, float hue) {
    t = clamp(t, 0.0, 1.0);
    float3 lab;
    if (t < 0.40) {
        lab = mix(p.s0, p.s1, smoothstep(0.0, 1.0, t * 2.5));
    } else if (t < 0.78) {
        lab = mix(p.s1, p.s2, smoothstep(0.0, 1.0, (t - 0.40) * (1.0 / 0.38)));
    } else {
        lab = mix(p.s2, p.s3, smoothstep(0.0, 1.0, (t - 0.78) * (1.0 / 0.22)));
    }
    float ch = cos(hue), sh = sin(hue);
    lab.yz = float2(lab.y * ch - lab.z * sh, lab.y * sh + lab.z * ch);
    return mh_oklab_to_linear(lab);
}

/// The last thing every field does. One code value of triangular-PDF
/// interleaved-gradient dither, in the encoded space where the quantization
/// actually happens. Triangular rather than uniform because uniform dither
/// leaves a faint texture of its own in flat areas; triangular does not.
static inline half4 mh_out(float3 linearRGB, float2 pixel) {
    float3 c = mh_linear_to_srgb(linearRGB);
    float n = fract(52.9829189 * fract(dot(pixel, float2(0.06711056, 0.00583715))));
    float tri = n < 0.5 ? (sqrt(2.0 * n) - 1.0) : (1.0 - sqrt(max(0.0, 2.0 - 2.0 * n)));
    c += tri * (1.0 / 255.0);
    return half4(half3(saturate(c)), 1.0h);
}

/// A soft knee, the same one the route curtain uses. Below the knee nothing
/// changes; above it the tail compresses asymptotically instead of clipping,
/// which is what stops a bright field turning into flat white paper.
static inline float mh_knee(float x, float knee) {
    return x < knee ? x : knee + (1.0 - knee) * (1.0 - exp(-(x - knee) / max(1.0 - knee, 1e-3)));
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
/// about 1.0 while its body sits between 0.35 and 0.7. In this family the spine
/// is the specular highlight and the hottest interior core, and nothing else is
/// allowed near the top.
static inline float mh_tier(float e) {
    float x = clamp(e, 0.0, 1.0);
    const float K = 0.78;
    float body = (x / K) * 0.72;
    float peak = 0.72 + ((x - K) / (1.0 - K)) * 0.28;
    return mix(body, peak, smoothstep(K - 0.10, K + 0.10, x));
}

/// THE ONE PLACE ENERGY BECOMES LIGHT. All twelve species compute a density in
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
/// knee compresses the same overshoot asymptotically, so a specular or the core
/// of a comet keeps its shape instead of becoming a patch.
static inline float3 mh_lit(MHPalette pal, float e, float glow,
                            float base, float span, float emis, float hue) {
    float G = max(glow, 0.0);
    float en = clamp(mh_knee(max(e, 0.0) * (0.35 + 0.65 * G), 0.92), 0.0, 1.0);
    float tRail = clamp(base + span * mh_tier(en), 0.0, 1.0);
    float3 col = mh_shade(pal, tRail, hue);
    // Emission is gated to the specular, not to the tone: the rail reaches the
    // top routinely, and emission from the whole amber body would put the ground
    // back up and flatten the very hierarchy mh_tier just built.
    return col * (1.0 + emis * G * smoothstep(0.72, 1.0, tRail));
}

/// THE ANTI-ALIAS GATE. Where a species puts full amplitude on a CHOSEN
/// frequency -- aura's shimmer along the ribbons, droplet's surface granulation
/// -- that frequency has a floor: below about two pixels a cycle it stops being
/// a form and becomes moire, which at 18 pt with the form scale wound down is a
/// real setting and not a theoretical one.
///
/// `cycles` is the structure's wavenumber in radians per uv unit, and the frame
/// gives the rest: one uv unit is min(size) points, which is min(size) *
/// pixelScale pixels. The gate returns 1 while the structure is comfortably
/// resolved and eases its CONTRIBUTION to nothing as it approaches a third of a
/// cycle per pixel, so structure that can no longer be drawn honestly becomes
/// its own soft average instead of a sparkle.
static inline float mh_aa(float cycles, float2 size, float pixelScale) {
    float px = max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0);
    float perPixel = max(cycles, 0.0) / (6.2831853 * px);
    return 1.0 - smoothstep(0.16, 0.36, perPixel);
}

/// THE CONTAINMENT. fl_edge's job, done for a circle instead of a screen.
///
/// The view clips these indicators to a Circle at length(uv) = 0.5, and a clip
/// is a hard edge: any form still carrying light when it arrives is sliced. In
/// this family the body has its own silhouette well inside that boundary, so
/// this is a safety net for the contact glow rather than the design of the
/// edge -- which is why the span is 0.26 here rather than the 0.31 the other
/// packs use. Called at 0.72, the fall runs from a uv radius of 0.36 to 0.49,
/// and the body's worst case is 0.339.
static inline float mh_containment(float2 uv, float reach) {
    float r = length(uv) * 2.0;
    return 1.0 - smoothstep(reach, reach + 0.26, r);
}

/// Turn the ball. One rotation about the vertical, which is the presence turning
/// to face you, and a tilt, so the pole never sits still long enough to become a
/// landmark the eye can lock onto.
static inline float3 mh_spin(float3 p, float ay, float ax) {
    float ca = cos(ay), sa = sin(ay);
    float3 q = float3(ca * p.x + sa * p.z, p.y, -sa * p.x + ca * p.z);
    float cb = cos(ax), sb = sin(ax);
    return float3(q.x, cb * q.y - sb * q.z, sb * q.y + cb * q.z);
}

/// ROLL. The third rotation, and aura needed it badly enough to be worth a kit
/// function.
///
/// mh_spin turns a body about the vertical and tips it toward the viewer, which
/// is everything a SPHERE ever needs -- a sphere has no orientation to give
/// away. A loop inside one does. Yaw and tilt alone leave every loop projecting
/// to an ellipse whose long axis is still horizontal on screen, so three ribbons
/// at three yaws and three tilts came out as three horizontal swooshes stacked
/// on each other, which is one swoosh. Rolling each ribbon about the view axis
/// first is the missing degree of freedom: it turns the projected ellipse, and
/// three ribbons at three rolls cross each other at three angles instead of
/// lying down together.
static inline float3 mh_roll(float3 p, float a) {
    float c = cos(a), s = sin(a);
    return float3(c * p.x - s * p.y, s * p.x + c * p.y, p.z);
}

/// THE LIVE SIGNALS, CONDITIONED ONCE.
///
/// The host hands two raw scalars and every species reads them through here,
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
/// THE STATE WEIGHTS. Voice is at full strength in LISTENING, which is where
/// level does its deepest work, and at 0.55 elsewhere -- a person talking over a
/// thinking assistant is still worth acknowledging, just not as though nothing
/// else were going on. Cadence is at full strength in THINKING and RESPONDING,
/// where a token stream is the thing actually happening, and at 0.6 elsewhere.
struct MHLive {
    float voice;   // level, shaped and state-weighted
    float pace;    // activity, shaped and state-weighted
};

static MHLive mh_live(float level, float activity, float stateIndex) {
    MHLive o;
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
static inline float mh_small(float2 size) {
    return 1.0 - smoothstep(16.0, 88.0, max(min(size.x, size.y), 1.0));
}

/// THE STATE READ, shared by all twelve species.
///
/// Two of the six states get an in-shader design; the rest are carried by the
/// per-state parameter sets the Swift layer interpolates, which is the right
/// division of labour -- a dial change is a dial change and does not belong in a
/// branch here.
///
/// SUCCESS (index 4) is this family's flash and it is always the same physics:
/// THE INTERIOR IGNITES AND SETTLES. `complete` is the breath of arrival: in
/// over about a third of a second, out over the rest of 1.2, on a curve whose
/// ends are flat so nothing snaps. `sweep` is the same window read as a
/// position, 0 to 1 over 0.95 s, and it is what each species runs the ignition
/// ALONG -- around aura's ribbons, out from droplet's core, once round limn's
/// rim, all the way along comet's orbit. `settled` is what is left afterwards
/// and holds for as long as the state does: the presence a little brighter and a
/// little more resolved than it was.
///
/// The light in a success is NOT an overlay. Every species multiplies its own
/// interior energy by (1 + complete), which brightens exactly what is already
/// there and leaves the dark dark: the surge travels through the species' own
/// structure because it IS the species' own structure, scaled.
///
/// RESPONDING (index 3) is decisive drive: the interior stops casting about and
/// acquires a DIRECTION, continuously, for as long as the state holds. `drive`
/// ramps in over half a second so entering the state is a lean and not a jolt.
struct MHState {
    float complete;   // success: the ignition, one breath
    float sweep;      // success: where the ignition has travelled to, 0...1
    float settled;    // success: what is left after it
    float drive;      // responding: directional urgency, held
};

static MHState mh_state(float stateIndex, float stateTau) {
    MHState o;
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

// MARK: - The motion law
//
// Two functions, and between them they are the reason this family reads as
// premium rather than as animation. Neither has any state between frames: any
// `time` renders the correct picture, which the screenshot rig and the scrub
// slider both depend on.

/// A PHASE THAT NEVER TICKS.
///
/// Anything that travels -- a ribbon around its axis, an arc around the rim, a
/// comet around its orbit -- goes through here instead of through `rate * t`. A
/// constant angular rate is the single most recognisable tell of a shader: the
/// eye locks onto the period within two laps and the presence becomes a loading
/// spinner.
///
/// The closed form is theta = w*t + (k*w/w2) * sin(w2*t + phi), which is the
/// exact integral of a rate w * (1 + k*cos(w2*t + phi)). Two consequences, both
/// of them the point: the rate is strictly positive for k < 1, so the motion
/// eases without ever stalling or reversing, and the modulation period (w2 is
/// about seven seconds and lane-dependent, so no two phases in a species agree)
/// is long enough that what the eye reads is a body that hurries and then
/// relaxes rather than a wobble.
///
/// k is capped at 0.72: past about 0.8 the slow part gets slow enough to look
/// like a stall, and a stall reads as a dropped frame.
static inline float mh_drift(float t, float rate, float wobble, float lane) {
    float k = clamp(wobble, 0.0, 0.72);
    float w2 = 0.137 + 0.0413 * lane;
    return rate * t + (k * rate / w2) * sin(w2 * t + lane * 1.71);
}

/// THE BREATH, and the rule is that the body is never at the top or the bottom
/// of it. Two periods, 9.4 s and 14.7 s, whose ratio is irrational enough that
/// their sum does not repeat inside any session anybody will sit through, so
/// there is no moment the eye can identify as "the start of the cycle". The
/// weights are 0.62 and 0.38 rather than equal because an even sum has a
/// symmetric envelope and reads as a sine again; uneven ones give the breath a
/// slow lean. Returns 0...1.
static inline float mh_breath(float t, float lane) {
    float a = sin(t * 0.668 + lane);
    float b = sin(t * 0.427 + lane * 2.3 + 1.1);
    return 0.5 + 0.5 * (0.62 * a + 0.38 * b);
}

// MARK: - THE GLASS BODY
//
// The shared kit. Every hero calls mh_body, marches its own interior between
// mh_body's entry point and mh_exit's length, shades the surface with
// mh_surface, and finishes on mh_present. The heroes differ ONLY in what they
// put inside.

/// The body's radius in uv. Not a dial: see the header on the clip. Everything
/// in this family is expressed in BODY UNITS, where 1.0 is this radius, so a
/// number like "the ribbon sits at 0.55" means something without arithmetic.
constant float MH_R = 0.300;

/// The refractive index of the glass. 1.18 rather than a physical 1.45: at 1.45
/// the limb swallows so much of the interior that the content the hero worked
/// for disappears into a two-pixel band, and the body reads as a marble rather
/// than as a presence with something happening inside it. 1.18 keeps the
/// magnifying edge and leaves the middle two thirds readable.
///
/// It came down from 1.22 for a second reason worth recording: a real glass
/// sphere shows an inverted GHOST of its own interior near the limb, and with
/// one small bright object inside -- comet's head -- the ghost was bright enough
/// and separate enough to read as a second comet. The species is one point of
/// light. MH_EXT below does most of the work of putting the ghost back in its
/// place; this took the last of it.
constant float MH_ETA = 1.0 / 1.20;

/// THE GLASS IS NOT PERFECTLY CLEAR, and this one number bought more depth than
/// anything else in the file. Every hero's transmittance carries a base
/// extinction per unit of path in addition to whatever its content absorbs, so
/// the far side of the body is genuinely dimmer than the near side: over a
/// two-unit chord a third of the light survives. That is what makes a ribbon
/// passing behind the middle read as passing BEHIND rather than merely crossing,
/// and it is what a body with no absorption at all can never look like, no
/// matter how many samples it takes.
constant float MH_EXT = 0.55;

/// How the surface is displaced. Heroes fill this and hand it to mh_body.
struct MHShape {
    float  amp;        // silhouette displacement, as a fraction of MH_R
    float  hi;         // the fine tremor mode, on top of the three slow ones
    float  gain;       // how much more the SHADING wobbles than the silhouette
    float3 flowDir;    // a travelling wave's axis: responding's directional lean
    float  flowAmp;
    float  flowPhase;
};

/// The still shape: three slow modes, no travelling wave.
static inline MHShape mh_shape(float amp, float hi, float gain) {
    MHShape s;
    s.amp = amp; s.hi = hi; s.gain = gain;
    s.flowDir = float3(0.0, 0.0, 1.0); s.flowAmp = 0.0; s.flowPhase = 0.0;
    return s;
}

/// THE DEFORMATION, and its exact gradient.
///
/// Three modes, each a sine of the dot product with a slowly rotating axis. On
/// the sphere that is a smooth low-order lobe pattern -- close enough to a low
/// band of spherical harmonics for the eye, and about a tenth of the cost. The
/// wavenumbers 1.7, 2.6 and 3.4 give roughly one and a half, two and three lobes
/// across the body: low enough that the result reads as "slightly out of round"
/// rather than as texture, which is the entire difference between a water
/// droplet and a golf ball.
///
/// The three axes rotate at 0.083, 0.061 and 0.047 rad/s -- periods of 76, 103
/// and 134 seconds, mutually incommensurate, so the body's shape never repeats
/// and never sits still. That slowness is deliberate: the deformation is the
/// thing the eye is least supposed to catch happening.
///
/// THE GRADIENT IS FREE AND EXACT. d/dn of sin(k * dot(n, a)) is k*cos(...)*a,
/// so the gradient falls out of the same trig the value needs. That matters more
/// than it sounds: it means the surface NORMAL is exact rather than
/// finite-differenced, which is what lets the specular highlight and the fresnel
/// rim ride the wobble cleanly instead of crawling with sampling noise.
///
/// `hi` is a fourth mode at wavenumber 6.9, which is texture rather than shape
/// and is only ever given amplitude by droplet's activity response. It gets its
/// own faster axis drift because a tremor that drifts as slowly as the body does
/// is not a tremor.
///
/// `flow` is a travelling planar wave -- sin(3.2 * dot(n, dir) + phase) -- and
/// it is how RESPONDING gets into the silhouette: a wave running around the body
/// in one direction, which is the only deformation on offer here that has an
/// unambiguous heading.
struct MHDeform { float d; float3 g; };

static MHDeform mh_deform(float3 n, float t, MHShape sh) {
    float a1 = t * 0.083, a2 = t * 0.061 + 2.10, a3 = t * 0.047 + 4.37;
    float3 ax1 = normalize(float3(cos(a1), 0.62, sin(a1)));
    float3 ax2 = normalize(float3(0.55, cos(a2), sin(a2)));
    float3 ax3 = normalize(float3(sin(a3), -0.44, cos(a3)));

    const float k1 = 1.70, k2 = 2.60, k3 = 3.40;
    const float w1 = 0.55, w2 = 0.30, w3 = 0.18;
    const float NORM = 1.0 / (w1 + w2 + w3);

    float u1 = dot(n, ax1), u2 = dot(n, ax2), u3 = dot(n, ax3);
    float d = (w1 * sin(k1 * u1) + w2 * sin(k2 * u2 + 1.9) + w3 * sin(k3 * u3 + 4.1)) * NORM;
    float3 g = (w1 * k1 * cos(k1 * u1) * ax1
              + w2 * k2 * cos(k2 * u2 + 1.9) * ax2
              + w3 * k3 * cos(k3 * u3 + 4.1) * ax3) * NORM;

    // The tremor. Its axis turns eight times faster than the body's modes do.
    if (sh.hi > 1e-4) {
        float a4 = t * 0.63;
        float3 ax4 = normalize(float3(cos(a4) * 0.8, sin(a4 * 0.77), sin(a4)));
        const float k4 = 6.90;
        float u4 = dot(n, ax4);
        d += sh.hi * sin(k4 * u4);
        g += sh.hi * k4 * cos(k4 * u4) * ax4;
    }

    // The travelling wave: responding, with a heading.
    if (sh.flowAmp > 1e-4) {
        const float kf = 3.20;
        float uf = dot(n, sh.flowDir);
        d += sh.flowAmp * sin(kf * uf + sh.flowPhase);
        g += sh.flowAmp * kf * cos(kf * uf + sh.flowPhase) * sh.flowDir;
    }

    MHDeform o; o.d = d; o.g = g;
    return o;
}

/// THE BODY, solved.
struct MHBody {
    float  m;      // membership: 1 inside, 0 outside, soft over the silhouette
    float3 P;      // the entry point on the deformed surface, in body units
    float3 N;      // the exact outward normal there
    float  Rd;     // the deformed radius along this pixel's direction
    float  rho;    // the pixel's in-plane radius, body units
    float  fres;   // 0 face-on, 1 at grazing
};

/// SOLVING A STAR-SHAPED SDF WITHOUT MARCHING IT.
///
/// The surface is r = Rd(n), which is star-shaped about the origin, so for an
/// orthographic view ray at in-plane radius rho the entry height z satisfies
/// z = sqrt(Rd(n)^2 - rho^2) with n itself depending on z. Two fixed-point
/// iterations solve it to well under a pixel for displacements this small, and
/// two evaluations of mh_deform is a tenth of what a sphere-trace would cost for
/// the same answer. The first pass uses the undeformed sphere's height as its
/// guess, which is never more than 8.5 per cent wrong by construction.
///
/// The projection is orthographic on purpose. A perspective camera on a body
/// this small buys nothing the eye can see and costs a divide per tap, and the
/// parallax that actually sells the volume comes from the REFRACTED interior
/// ray, not from the camera.
///
/// THE SILHOUETTE IS SOFT, and by two numbers added rather than multiplied: a
/// fixed 1.8 per cent of organic feather, because nothing in this house has a
/// hard edge, plus 1.3 pixels of anti-aliasing, because at 18 pt the fixed
/// feather is a fifth of a pixel and would alias to a staircase. The larger of
/// the two wins at each mount, which is what makes the edge look identical at
/// both.
///
/// THE NORMAL. For F(p) = |p| - Rd(p/|p|) the gradient is n minus the tangential
/// part of Rd's gradient over Rd -- exact, because mh_deform hands back the
/// gradient. `gain` then scales the perturbation past physical: the silhouette
/// is capped by the clip but the SHADING is not, so a droplet can look far more
/// liquid than its outline is allowed to be. That is a cheat and it is the right
/// one; the alternative is a body whose highlight barely moves.
static MHBody mh_body(float2 uv, float t, float px, MHShape sh) {
    MHBody o;
    // The clip is the law. Everything downstream trusts this cap.
    sh.amp = clamp(sh.amp, 0.0, 0.085);

    float2 s = uv / MH_R;
    o.rho = length(s);

    float z0 = sqrt(max(1.0 - min(o.rho * o.rho, 1.0), 0.0));
    float3 n0 = normalize(float3(s, z0) + float3(0.0, 0.0, 1e-6));
    float R0 = 1.0 + mh_deform(n0, t, sh).d * sh.amp;

    float z1 = sqrt(max(R0 * R0 - o.rho * o.rho, 0.0));
    float3 n1 = normalize(float3(s, z1) + float3(0.0, 0.0, 1e-6));
    MHDeform d1 = mh_deform(n1, t, sh);
    o.Rd = 1.0 + d1.d * sh.amp;

    float z2 = sqrt(max(o.Rd * o.Rd - o.rho * o.rho, 0.0));
    o.P = float3(s, z2);

    float3 gt = d1.g * sh.amp;
    gt = gt - dot(gt, n1) * n1;                       // the tangential part
    o.N = normalize(n1 - (gt * sh.gain) / max(o.Rd, 1e-3));

    float feather = max(0.018, 1.3 * px);
    o.m = 1.0 - smoothstep(o.Rd - feather, o.Rd + feather, o.rho);
    o.fres = 1.0 - clamp(o.N.z, 0.0, 1.0);
    return o;
}

/// THE BEND AT ENTRY. Snell, written out rather than borrowed from `refract`
/// so the total-internal guard is visible: with eta below 1 the discriminant
/// cannot go negative, but this function is also the obvious place a future
/// hero would raise the index, and a silent NaN at the limb is a black ring
/// around a glass ball.
static inline float3 mh_refract(float3 V, float3 N, float eta) {
    float ci = clamp(-dot(V, N), 0.0, 1.0);
    float k = 1.0 - eta * eta * (1.0 - ci * ci);
    if (k <= 0.0) return V;
    return normalize(eta * V + (eta * ci - sqrt(k)) * N);
}

/// How far the interior ray travels before it leaves. Solved against the
/// UNDEFORMED unit sphere: the interior march does not need the surface to a
/// fraction of a per cent, and a second deformation solve per pixel would double
/// the body's cost to move the last tap by a pixel. Capped at 2.2 so a grazing
/// pixel outside the silhouette, where the membership is zero anyway, cannot
/// send the loop off into space.
static inline float mh_exit(float3 P, float3 rd) {
    float b = dot(P, rd);
    float c = dot(P, P) - 1.0;
    float disc = b * b - c;
    if (disc <= 0.0) return 0.0;
    return clamp(-b + sqrt(disc), 0.0, 2.2);
}

/// THE INTERIOR HAZE. A faint volumetric air every hero adds to its own content,
/// advecting slowly in all three axes so it is never a still texture. One octave,
/// not four: this is the medium the content hangs in, and an fBm here would give
/// the glass a cloudiness that competes with whatever the hero is actually about.
/// The five taps that already exist do the averaging that would otherwise need
/// the extra octaves.
static inline float mh_haze(float3 p, float t, float scale) {
    float3 q = p * scale + float3(t * 0.051, -t * 0.033, t * 0.089);
    return clamp(0.5 + 0.85 * mh_noise3(q), 0.0, 1.0);
}

/// WHAT GETS IN. The Fresnel split, and it is the piece the first two cuts of
/// this file were missing.
///
/// Light arriving at glass near head-on mostly goes through; light arriving near
/// grazing mostly bounces off. So the interior a pixel can see is weighted by
/// how square that pixel's view is to the surface, and near the limb almost
/// nothing gets through at all. Three things fall out of one line, and each of
/// them was a separate problem before it:
///
///   THE SHELL READS. The rim goes bright and reflective exactly where the
///   interior goes dark, so there is a real boundary between the two rather than
///   content bleeding out to the silhouette. That contrast IS the look of the
///   reference orbs and no amount of rim brightness produces it on its own.
///   DEPTH GETS AN EDGE FALLOFF for free -- content near the limb is seen
///   through more glass at a worse angle, and now it dims accordingly.
///   THE GHOST DIES. A sphere lenses a second, inverted image of its own
///   interior into the region near the limb, and with one small bright object
///   inside -- comet's head -- that ghost was bright enough to read as a second
///   comet. It lives at high fresnel by construction, which is precisely where
///   this takes it down to a tenth.
///
/// The exponent is 2.2 and the floor is 0.12: a real dielectric's curve is
/// steeper than that, and a steeper one here empties the outer third of the body
/// and makes the presence read as a small object inside a large lens.
static inline float mh_transmit(float fres) {
    return 1.0 - 0.88 * pow(clamp(fres, 0.0, 1.0), 2.2);
}

/// THE SCATTER, and it is the difference between light in glass and stickers on
/// black.
///
/// Round one built every hero as emissive content read at a point: a ribbon was
/// bright exactly where the ribbon was and the medium a millimetre away was
/// ink. That is not what a luminous body inside a translucent solid looks like.
/// Real glass is never optically empty -- it scatters, so every bright thing
/// inside it throws a wide soft glow into the material AROUND it, and what you
/// actually see is the object plus its own light living in the fog. Without that
/// term the interiors read as black voids with objects pasted in, which is
/// exactly the verdict round one got.
///
/// The law is one line and every hero spends it the same way. Content here is
/// built from gaussians, so the narrow term is exp(-arg) for some squared
/// normalised distance `arg`; scaling that same argument by 1/k^2 gives the
/// identical shape k times wider, for the cost of one more exp and no new
/// geometry. k is 3.2 -- ten times the area -- which is wide enough to fill the
/// space between two ribbons and tight enough that the object inside it is still
/// an object. Amplitude stays low, a sixth or so, because scatter is a haze
/// around a light and not a second light.
///
/// It dims with depth for free: the scatter is accumulated inside the march, so
/// MH_EXT and the running transmittance attenuate it exactly as they attenuate
/// everything else, and a glow thrown from the far side of the body arrives
/// dimmer than the same glow thrown from the near side.
constant float MH_SCATTER_K = 0.098;   // 1 / 3.2^2

static inline float mh_scatter(float arg, float amp) {
    return amp * exp(-arg * MH_SCATTER_K);
}

/// THE MEDIUM. What the glass is made of when nothing is happening in it.
///
/// The companion to the scatter and the other half of the same verdict: a body
/// whose ambient interior is zero reads HOLLOW, a shell with a hole in it, and
/// no amount of scatter off the content fixes the parts of the volume the
/// content is nowhere near. So there is a floor. It is a soft radial fog --
/// thickest through the middle, gone by the shell so it never fights the rim --
/// modulated by the same slowly advecting noise the haze used, at 0.55 plus 0.45
/// of it so the noise gives the fog structure without ever punching a hole in
/// it.
///
/// Kept deliberately faint. At the amplitudes the heroes give it this lands
/// around a fifth of the way up the rail: a dark warm interior you can see the
/// far wall through, not a glowing ball. The test is that the sphere reads as
/// FULL at a glance and you still cannot say what colour the empty part is.
static inline float mh_medium(float3 p, float t, float scale) {
    float fog = 1.0 - smoothstep(0.05, 0.98, length(p));
    return fog * (0.55 + 0.45 * mh_haze(p, t, scale));
}

/// CONTENT FLOATS, IT DOES NOT TOUCH THE WALL. Interior structure that reaches
/// the shell reads as painted ON the shell, which is the exact failure this
/// family exists to avoid, and it also fights the rim for the same pixels. So
/// every hero fades its content out from 0.72 of the radius and it is gone by
/// 0.99. What is left in that outer shell is haze, rim and specular: the glass
/// itself.
static inline float mh_inside(float3 p) {
    return 1.0 - smoothstep(0.76, 0.99, length(p));
}

/// THE SURFACE, shared by every hero.
struct MHSurface {
    float rim;    // fresnel edge light
    float spec;   // the highlight, both lobes
    float glow;   // the contact bloom outside the silhouette
};

/// The key sits up and to the left and drifts about four degrees over half a
/// minute, which is enough that the highlight is never in the same place twice
/// and not enough that anybody watches it move. Screen y runs DOWN in a
/// colorEffect, so up-left is negative in both.
///
/// TWO SPECULAR LOBES. A tight one at 34 is the glint that reaches the rail's
/// cream stop and gives the body its brightest pixel; a broad one at 5 at a
/// sixth of the amplitude is the sheen that tells you the whole upper half of
/// the body is turned toward a light. One lobe alone gives either a plastic dot
/// or a foggy wash; the pair is what reads as glass.
///
/// THE RIM IS NOT A RING. pow(fresnel, 3) puts the edge light in the outer sixth
/// of the body, and it is then weighted by which way that edge faces: 55 per
/// cent everywhere plus 45 per cent on the side AWAY from the key, which is the
/// wrap light every product photograph of a glass object has and which an even
/// ring never looks like. It rides the deformed normal, so on droplet the rim
/// traces the wobble around the body.
///
/// THE CONTACT GLOW pools beneath. It is capped low -- a tenth of the body's
/// energy -- because the brief for it is "barely there": its job is to stop the
/// silhouette meeting the ink as a cut line, not to be a halo anybody notices.
static MHSurface mh_surface(MHBody b, float t, float small, float rimK, float specK, float glowK) {
    MHSurface o;

    // The key sits further out than a beauty light would: at (-0.52, -0.60) the
    // highlight lands at about 0.45 of the radius, clear of whatever the hero
    // has put in the middle. Pulled in toward the axis it sat directly on top of
    // droplet's core and comet's orbit and stopped being a separate event.
    float dr = t * 0.21;
    float3 key = normalize(float3(-0.52 + 0.055 * sin(dr),
                                  -0.60 + 0.045 * cos(dr * 0.83),
                                   0.61));
    float3 H = normalize(key + float3(0.0, 0.0, 1.0));
    float nh = clamp(dot(b.N, H), 0.0, 1.0);
    // THE TIGHT LOBE IS SIZE-ADAPTIVE, and it has to be: a 96-exponent highlight
    // covers about four pixels at 120 pt and a third of one at 18 pt, where it
    // would flicker in and out as the body wobbled underneath it. At 18 pt the
    // exponent drops to 16, which spreads the same light over two or three
    // pixels -- still unmistakably a glint, and stable.
    //
    // 96 rather than the 58 the first cut used, and the reason is the value
    // hierarchy rather than realism. At 58 the glint's saturated core was a
    // tenth of the frame across: a second bright object competing with whatever
    // the hero had put inside, and on comet it read as a second comet. A
    // specular is meant to be the brightest thing in the picture and one of the
    // smallest. Amplitude is left to the caller, because how much sheen a body
    // wears is a species decision -- droplet's whole surface is the point, and
    // limn's is a dark bead with one catchlight on it.
    float tight = mix(96.0, 16.0, small);
    o.spec = (pow(nh, tight) + 0.09 * pow(nh, 4.0)) * b.m * specK;

    float wrap = 0.55 + 0.45 * clamp(dot(normalize(b.N.xy + float2(1e-4)),
                                         normalize(float2(0.42, 0.50))), 0.0, 1.0);
    // Exponent 4.6, and it was fitted against a capture rather than chosen: at 3
    // the rim is a broad wash that reads as the body being lit from behind, and
    // the shell's boundary disappears into it. At 4.6 the light lives in the
    // outer eighth and the eye gets a CRISP EDGE with soft content behind it,
    // which is the single strongest cue that there is a shell at all.
    o.rim = pow(b.fres, 3.9) * b.m * wrap * rimK;

    // Outside only: (1 - m) is zero under the silhouette and rises through it.
    // 0.13 body units of width, down from 0.20: at 0.20 the bloom was wide
    // enough to read as a second disc around the body, and its outer edge met
    // the containment's falloff as a visible dark ring. At 0.13 it is what it
    // was briefed as -- the silhouette not meeting the ink as a cut line.
    float outr = (b.rho - b.Rd) / 0.13;
    float pool = 0.55 + 0.55 * smoothstep(-0.25, 0.85, b.P.y);
    o.glow = exp(-outr * outr) * (1.0 - b.m) * pool * glowK;
    return o;
}

/// THE FINISH. Ink underneath, the body composited into it by the containment,
/// the same knee the route curtain puts on its surface colour, and the dither
/// last. Every hero ends on this line, which is most of why they read as one
/// material with four things happening inside it.
///
/// `hue` is the spread offset the hero accumulated, already weighted by which
/// part of the picture is carrying colour: a pixel that is mostly specular gets
/// almost none of it, because a highlight is the colour of the light rather than
/// the colour of the thing it landed on.
static inline half4 mh_present(float energy, float hue, float2 uv,
                               MHPalette pal, float glow,
                               half4 inkColor, float2 position, float pixelScale) {
    float3 field = mh_lit(pal, energy, glow, 0.0, 1.0, 0.34, hue);
    float3 inkLin = mh_srgb_to_linear(float3(inkColor.rgb));
    float3 rgb = mix(inkLin, field, mh_containment(uv, 0.72));
    rgb = float3(mh_knee(rgb.r, 0.90), mh_knee(rgb.g, 0.90), mh_knee(rgb.b, 0.90));
    return mh_out(rgb, position * pixelScale);
}

/// The spread cap. 0.50 radians is about 29 degrees of OKLAB hue either side of
/// the anchor: amber to gold one way, amber to ember the other. Two or three
/// hues in conversation, which is the reference-orb look, and nowhere near a
/// second hue family, which is the rule.
constant float MH_SPREAD = 0.50;

/// The number of taps down the interior ray. Five, and the argument for exactly
/// five: four leaves a visible banding when a bright core passes between two
/// sample planes, and six costs twenty per cent more for a difference nobody
/// found in a side-by-side. The taps are placed at the segment midpoints, which
/// is a midpoint Riemann rule and is second-order accurate -- the same five
/// samples placed at the segment edges band noticeably worse.
#define MH_TAPS 5

// MARK: - 1. Aura

// AURA. Ribbons of coloured light, drifting slowly INSIDE the glass.
//
// THE SPECIES IS ABOUT DEPTH, and the test it has to pass is that the ribbons
// cross in front of and behind one another rather than sliding past each other
// in a plane. Each ribbon is an open SHEET: a gently rippling surface passing
// right through the body, thin through its thickness, wide across its face,
// displaced along its own frame's normal and rolled and tilted differently from
// the others. The interior march then does the rest for free -- a tap that lands
// in a near sheet attenuates what the far ones contribute behind it, so the
// crossings resolve as occlusion rather than as addition. Addition is what a
// painted disc does and it looks like coloured smoke; occlusion looks like two
// surfaces at two depths.
//
// WHY SHEETS AND NOT LOOPS. The build this species started from put each ribbon
// at a fixed cylindrical radius around a tilted axis -- a closed loop, which is
// the obvious way to say "circulating inside a sphere" and which cost three
// rounds before the reason it could not work became clear. A loop projects to an
// ellipse, and a band of finite thickness laid on an ellipse has two places
// where it turns edge-on to the viewer and pinches to nearly nothing. Those
// pinches are corners. Widening the band leaves corners; softening its edges
// leaves corners; slowing it down leaves corners that move slowly. It read as
// calligraphy every time, because a stroke with a sharp turn in it IS
// calligraphy, and diffusing the edges does not change what the centreline is
// doing. A sheet has no turns because it has no ends inside the volume: it
// enters one side of the glass and leaves the other, the way a length of silk
// hanging in water does. What that gives up is the loop's literal circulation.
// What it buys is that every part of the ribbon is a broad soft surface.
//
// LEVEL LIFTS AND QUICKENS THEM. Voice deepens the ripple (the sheets rise and
// fall further as they cross, so they sweep more depth), speeds their travel,
// and brightens them. All three at once, because a ribbon that only got brighter
// would read as a dimmer being turned and one that only got faster would read as
// a frame-rate change; the combination reads as the material getting more
// energetic, which is what a voice does to it.
//
// ACTIVITY ADDS A FINE SHIMMER along them: a high-frequency field sampled in the
// volume, gated by mh_aa so it switches itself off at the sizes where it would
// be moire. One noise per tap for all the sheets, not one per sheet, which is
// why this species is affordable.
//
// RESPONDING PUTS THEM IN FORMATION. The tilts converge halfway toward a common
// one and the travel roughly doubles, so ribbons drifting at their own angles
// become ribbons streaming together. Only halfway, and the ROLLS do not converge
// at all: collapsing every orientation onto one made the sheets coincident, and
// coincident sheets are one bright clot rather than a stream.
//
// SUCCESS IGNITES THEM ALONG THEIR LENGTH: a bright band runs once around the
// body on the state's sweep -- the ignition travels, it does not flash in place
// -- and the whole interior lifts under it and then settles brighter.
//
// SPREAD (c2) puts each ribbon on its own hue: one rotated warm, one rotated
// cool, the third at the far end. At spread 0 they are all the anchor and the
// species still works; at 0.5 they are neighbours in conversation, which is the
// reference-orb look and the reason this knob exists.
//
// SIZE: two ribbons is the default composition and the third is what c0 buys,
// so the small mounts are not counting down from a crowd -- they drop the third
// entirely, take the second to a third of its weight, and thicken what is left
// by 85 per cent. At 18 pt what survives is one broad swath of light crossing a
// filled body, which is the species said in one mark.
[[ stitchable ]] half4 mh_aura(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float ribbonK = clamp(c0, 0.0, 1.0);   // how many, and how wide
    float swirlK  = clamp(c1, 0.0, 1.0);   // how fast they travel
    float spreadK = clamp(c2, 0.0, 1.0);   // the hue conversation
    float d3K     = clamp(c3, 0.0, 1.0);   // how much depth they sweep

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    // The body: a whisper of deformation. This hero's business is inside, and a
    // wobbling shell would compete with the ribbons for the same attention.
    MHShape sh = mh_shape(0.022 + 0.008 * mh_breath(t, 0.4), 0.0, 1.35);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_refract(V, b.N, MH_ETA);
    float L = mh_exit(b.P, rd);

    // THE RIBBONS COUNT DOWN, and they count down twice rather than once. The
    // third goes first, by the chip; the second follows it down to a third of
    // its weight at the smallest mount, and what is left at 18 pt is ONE ribbon
    // with a companion behind it. Two full ribbons down there was still two
    // objects' worth of light in a bead thirteen points across, and they merged
    // into a bright amoeba that said nothing. One says "a ribbon of light,
    // turning", which is the species in the fewest possible marks.
    //
    // Both are crossfades and not switches, because both ribbons are smooth
    // fields and a count that pops is a count the eye catches.
    // TWO AT THE DEFAULT, THREE IF ASKED. Three wide ribbons inside a body this
    // small do not have room to stay three things: they overlap, and overlapping
    // ribbons are one ribbon with a complicated outline, which is what round two
    // drew. Two well-separated ones read as two, cross cleanly, and leave enough
    // dark glass between them for the crossing to mean something. So the third
    // is what c0 BUYS -- the knob is called `ribbons` and now it earns the name
    // -- and it is gone at the default and at every small mount.
    float third  = smoothstep(0.55, 0.95, ribbonK) * (1.0 - smoothstep(0.22, 0.62, small));
    float second = mix(1.0, 0.34, smoothstep(0.52, 0.94, small));
    float w3 = 0.55 + 0.45 * ribbonK;

    // A RIBBON IS A SHEET, NOT A LOOP, and getting that wrong cost this species
    // three rounds of tuning that could not have worked.
    //
    // The build it started from put each ribbon at a fixed cylindrical radius
    // around its own tilted axis: a closed loop, which is the obvious way to say
    // "circulating inside a sphere". The trouble is what a loop DRAWS. Projected
    // to the screen it is an ellipse, and an ellipse of finite thickness has two
    // places where the band turns edge-on to the viewer and pinches to nearly
    // nothing. Those two pinches are corners. Widen the band and they are still
    // corners; soften the edges and they are still corners; slow it down and
    // they are corners that move slowly. Every version of it read as
    // calligraphy, because a stroke with a sharp turn in it IS calligraphy, and
    // no amount of diffusion at the edges changes what the centreline is doing.
    //
    // So the ribbon is now an open SHEET: a gently rippling surface passing
    // through the body, thin through its thickness, wide across its face, and
    // unbounded along its length until the glass runs out. It has no turns
    // because it has no ends inside the volume -- it enters one side and leaves
    // the other -- which is exactly what a length of silk hanging in water looks
    // like. What it gives up is the loop's literal circulation; what it buys is
    // that every part of it is a broad soft surface, and that two of them at two
    // orientations cross as two SURFACES at different depths rather than as two
    // outlines overlapping.
    //
    // Three numbers describe one: `wh` is the sheet's thickness, `bw` is how
    // wide across the face it is before it fades out, and the ripple amplitudes
    // below are how much it undulates as it goes. Thickness to width is about
    // one to four, which is a ribbon; at one to one it would be a slab.
    float wh = (0.105 - 0.020 * ribbonK) * mix(1.0, 1.85, small);
    float bw = (0.400 - 0.070 * ribbonK) * mix(1.0, 1.25, small);
    wh *= S; bw *= S;

    // TRAVEL. Eased, per-ribbon lanes, quickened by voice, by cadence and again
    // by responding, which is where the three become one stream.
    //
    // SLOWED BY NEARLY HALF from round one. A ribbon at 0.51 rad/s was something
    // you decoded; at 0.29 it is something you watch. The rest of the batch's
    // rates are calm and this one was not, which is most of why it read as the
    // agitated hero.
    float rate = (0.17 + 0.24 * swirlK)
               * (1.0 + 0.85 * live.voice + 0.45 * live.pace + 1.05 * st.drive);
    float ph0 = mh_drift(t, rate,        0.40, 1.0);
    float ph1 = mh_drift(t, rate * 0.83, 0.52, 2.0) + 2.1;
    float ph2 = mh_drift(t, rate * 1.17, 0.34, 3.0) + 4.3;

    // THE RIPPLE. How much the sheet undulates as it crosses the body, and it is
    // the whole of `depth3d`: a flat sheet is a pane of glass, and a sheet that
    // rises and falls by a fifth of the radius as it goes is cloth. Voice pushes
    // it, because a ribbon moving more is the most legible thing voice can do to
    // this species that is not simply brightness.
    //
    // Kept low deliberately. Past about 0.3 the sheet starts folding back on
    // itself along the view ray and the same ribbon is hit twice by one ray,
    // which draws a bright seam where a fold is edge-on -- the loop's cusp
    // problem returning by another road.
    float amp = (0.098 + 0.130 * d3K) * (1.0 + 0.55 * live.voice) * mix(1.0, 0.78, small);

    // THE OFFSETS, and this is what puts the sheets at different DEPTHS. Each is
    // displaced along its own frame's normal, and since the frames are rolled
    // and tilted differently, three displacements along three different
    // directions put three surfaces genuinely apart in the volume. That
    // separation is what the parallax is made of: when the body turns, near
    // sheets slide across far ones at visibly different rates, which cannot
    // happen when they occupy the same shell.
    float of0 = mix(-0.26, -0.20, small);
    float of1 = mix( 0.24,  0.20, small);
    float of2 = 0.02;

    // THE AXES. Each ribbon has its own slow precession; responding pulls all
    // three toward a common axis, which is the alignment the state asks for.
    float align = st.drive;
    // RESPONDING ALIGNS THEM, BUT IT MUST NOT MERGE THEM. Collapsing every roll
    // and tilt onto one value made the ribbons coincident, and coincident
    // ribbons are one bright clot rather than a stream: the state read as a
    // mess instead of as decisive. So the rolls -- which are what keeps the two
    // loops in visibly different planes -- do not align at all, and the tilts
    // align only halfway. What drive actually does is make them travel together
    // and faster, in formation, which is what "answering now" looks like.
    float alignT = 0.5 * align;
    float ro0 = 0.15 + 0.22 * sin(t * 0.031);
    float ro1 = 2.05 + 0.26 * sin(t * 0.024 + 2.2);
    float ro2 = 3.85 + 0.20 * sin(t * 0.019 + 4.6);
    float ay0 = mix(mh_drift(t, 0.061, 0.5, 4.0),          0.30, alignT);
    float ax0 = mix(0.62 + 0.16 * sin(t * 0.043),          0.34, alignT);
    float ay1 = mix(mh_drift(t, 0.047, 0.6, 5.0) + 2.4,    0.30, alignT);
    float ax1 = mix(-0.78 + 0.14 * sin(t * 0.037 + 1.9),   0.34, alignT);
    float ay2 = mix(mh_drift(t, 0.039, 0.4, 6.0) + 4.7,    0.30, alignT);
    float ax2 = mix(0.06 + 0.20 * sin(t * 0.029 + 3.4),    0.34, alignT);

    // The shimmer's wavenumber in radians per uv unit, for the gate. The field
    // is read at 7.2 body units, and one body unit is MH_R uv units.
    float shimGate = mh_aa(6.2831853 * 7.2 / (MH_R * S), size, pixelScale)
                   * (1.0 - small);
    float shimAmt = shimGate * (0.20 + 0.75 * live.pace);

    // x: energy through the volume, y: the same energy weighted by hue offset.
    // Dividing one by the other at the end gives the hue this pixel's interior
    // actually is, rather than the hue of whichever ribbon was sampled last.
    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        // ONE SHEET, three times. In the ribbon's own rolled and tilted frame the
        // surface is q.y = a ripple in q.x and q.z, offset along the frame's
        // normal; `dh` is the signed distance to it and `q.z` is how far across
        // its face this point is. Both go into one squared argument, so the
        // ribbon is a gaussian slab in one direction and a gaussian band in the
        // other, and every edge it has is diffuse in both.
        //
        // The ripple uses TWO incommensurate waves rather than one. One wave is
        // a corrugation and reads as a machined part; two at 1.7 and 1.1 with
        // different phases give the surface a slow irregular lift that never
        // repeats along its length, which is what cloth does.
        //
        // THE GRADIENT ALONG THE LENGTH is the other half of the silk read. A
        // ribbon of even brightness is a stroke however soft its edges are; real
        // cloth catches the light along part of its run and loses it along the
        // rest. So each sheet is multiplied by one slow wave in q.x, drifting at
        // its own rate so the bright stretch travels ALONG the ribbon rather
        // than with it. Floor at 0.58, never zero: a ribbon that goes fully dark
        // has been cut into pieces, and pieces are not silk.
        //
        // The scatter is added on the same argument the narrow term uses, so it
        // costs one exp and cannot ever be misregistered against the sheet it
        // belongs to.

        // Ribbon 0.
        float3 q = mh_spin(mh_roll(p, ro0), ay0, ax0) / S;
        float dh = q.y - of0 - amp * (sin(1.70 * q.x + ph0) + 0.62 * sin(1.10 * q.z - ph0 * 0.8 + 2.1));
        float a0 = (dh * dh) / (wh * wh) + (q.z * q.z) / (bw * bw);
        float g0 = 0.58 + 0.42 * (0.5 + 0.5 * sin(2.1 * q.x - t * 0.083 + 0.7));
        float e0 = (exp(-a0) + mh_scatter(a0, 0.17)) * g0;

        // Ribbon 1. Different ripple frequencies so the two never breathe
        // together, and a wider face, because two identical ribbons at two
        // angles still read as one thing said twice.
        q = mh_spin(mh_roll(p, ro1), ay1, ax1) / S;
        dh = q.y - of1 - amp * 0.85 * (sin(1.30 * q.x + ph1) + 0.58 * sin(1.55 * q.z - ph1 * 0.7 + 4.3));
        float a1 = (dh * dh) / (wh * wh) + (q.z * q.z) / (bw * bw * 1.30);
        float g1 = 0.58 + 0.42 * (0.5 + 0.5 * sin(1.6 * q.x - t * 0.061 + 3.9));
        float e1 = (exp(-a1) + mh_scatter(a1, 0.17)) * g1 * second;

        // Ribbon 2, the one small sizes give up and the knob buys back.
        float e2 = 0.0;
        if (third > 0.002) {
            q = mh_spin(mh_roll(p, ro2), ay2, ax2) / S;
            dh = q.y - of2 - amp * 1.15 * (sin(2.10 * q.x + ph2) + 0.55 * sin(0.90 * q.z - ph2 * 0.9 + 1.4));
            float a2 = (dh * dh) / (wh * wh) + (q.z * q.z) / (bw * bw * 0.80);
            float g2 = 0.58 + 0.42 * (0.5 + 0.5 * sin(1.3 * q.x - t * 0.047 + 1.9));
            e2 = (exp(-a2) + mh_scatter(a2, 0.17)) * g2 * third;
        }

        // THE IGNITION travels around the ribbons on the success sweep. A von
        // Mises bump in the angle rather than a gaussian, because it wraps with
        // no seam: a seam here would be a dark notch running across all three
        // ribbons at once, which is the most visible artifact this file could
        // have shipped.
        float lap = 1.0;
        if (st.complete > 0.001) {
            float ang = atan2(p.z, p.x);
            lap += st.complete * (0.18 + 0.80 * exp(2.4 * (cos(ang - st.sweep * 6.2831853) - 1.0)));
        }

        float ribbons = (e0 + e1 + e2) * w3 * lap;

        if (shimAmt > 0.002) {
            ribbons *= 1.0 + shimAmt * mh_noise3(p * (7.2 / S) + float3(0.0, 0.0, t * 0.9));
        }

        // THE HUE CONVERSATION. Each ribbon carries its own offset; the sum is
        // weighted by which ribbon is actually at this tap, so a pixel where two
        // ribbons cross gets the average and the crossing reads as a blend
        // rather than as a hard seam between two colours.
        float hueW = (e0 * -0.70 + e1 * 0.55 + e2 * 1.0) * w3 * lap;

        // THE MEDIUM INTEGRATES, and this is where the first cut of every hero
        // in this file went wrong in the other direction: an amplitude that
        // looks modest at one tap is multiplied by the path length and the gain,
        // so 0.085 became most of the picture and the body turned into an orange
        // ball with the species lost inside it. Budget it the honest way --
        // amplitude times a typical path of about 1.8 times the gain is what
        // actually lands on the rail -- and 0.075 is a fog you can see the far
        // wall through.
        float med = mh_medium(p, t, 2.6 / S) * 0.075;
        float e = (ribbons * 1.45 + med) * fade;

        acc.x += e * trans * ds;
        acc.y += hueW * 1.45 * fade * trans * ds;
        // Ribbons occlude: this is the line that turns three curves into three
        // depths. The coefficient is fitted against a capture -- at 9 the far
        // ribbon vanishes entirely and the body loses its sense of fullness, at
        // 1.5 nothing occludes anything and it is smoke again.
        trans *= exp(-(4.50 * e + MH_EXT) * ds);
    }

    // THE GAIN, and it is the number the whole species lives or dies on. A tap
    // through a ribbon's spine contributes about density 1 times 1.45 times a
    // segment of 0.38, so 1.55 puts that spine near 0.85 -- which mh_tier reads
    // as cream. The ribbon's shoulders land near 0.5, which is the amber body,
    // and the haze lands near 0.15, which is shell. Three tiers from one number.
    // The first cut ran this at 5.6 and every pixel of every ribbon came out at
    // the specular stop: a cream splat with no structure in it at all.
    // THE SMALL MOUNT NEEDS LESS GAIN, NOT THE SAME. At 18 pt the ribbons are
    // more than twice as thick and the body is the same size, so a far larger
    // share of every ray is inside a ribbon and the identical gain drove the
    // whole interior past the knee: the 18 pt tile came out as a cream amoeba
    // with the structure cooked out of it. Down 40 per cent, the small mount
    // keeps the same three tiers the large one has.
    float interior = acc.x * 2.60 * mix(1.0, 0.92, small) * b.m * mh_transmit(b.fres)
                   * (1.0 + 0.45 * st.complete) * (1.0 + 0.22 * st.settled);
    float hue = (acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD;

    // The rim's amplitude went UP when its exponent tightened: the same light in
    // an eighth of the width has to be brighter to be the same edge.
    MHSurface sf = mh_surface(b, t, small, 0.88 + 0.40 * live.voice, 0.52, 0.16);
    // The rim borrows the interior's colour, because it IS the interior seen
    // edge-on through more glass. The specular does not: it is the key light.
    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, hueShift, depth);
    return mh_present(e, hueMix, uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 2. Droplet

// DROPLET. The body itself is the species: a sphere of water in free fall.
//
// THIS IS THE ONE HERO WHERE THE SHELL DOES THE TALKING, so everything the other
// three keep at a whisper is turned up and everything they put inside is turned
// down. The deformation runs at 0.075 against their 0.022, the shading gain runs
// at 2.4 against their 1.35, and the interior is very nearly clear: one soft
// luminous core, a little haze, nothing else. A clear interior is not an empty
// one -- it is what lets the refraction be visible, because the only way to see
// a lens is to see something through it, and here the something is the core.
//
// THE HEART IS CENTRED, and only just off it. A whisper of lag -- under three
// per cent of the radius, on three incommensurate periods -- so the light is
// never nailed to the exact middle and the drop still reads as liquid carrying
// its contents a beat behind. Any more than that and it stops being the body's
// heart and becomes a lamp rattling around inside a shell. It is solved at the
// view ray's closest approach rather than sampled by the march, which is what
// makes it ROUND: five taps through an object this small drew the shape of the
// sampling instead of the shape of the object, and that read as a smear.
//
// LEVEL IS AN INHALE. Voice swells the whole body -- radius up by up to five per
// cent, on top of the deformation, which is why both are capped -- and raises
// the deformation with it, and brightens the core. The swell is shaped by a
// breath so it arrives and leaves on a curve rather than tracking the microphone
// sample by sample; a body that follows the raw envelope reads as a VU meter,
// and a body that lags it slightly reads as breathing.
//
// ACTIVITY IS TREMOR. Cadence gives the fourth deformation mode amplitude -- the
// one at wavenumber 6.9, drifting eight times faster than the body's own modes.
// Tiny surface ripples, the way a drop of water shivers when something touches
// its container. It is gated by mh_aa: at 18 pt a 6.9-mode ripple is under a
// pixel and would only be aliasing.
//
// RESPONDING GIVES THE WOBBLE A HEADING. mh_deform's travelling wave switches on
// and runs around the body in one direction at about a third of a hertz. A
// wobble that goes everywhere is thinking; a wave that goes one way is
// answering.
//
// SUCCESS IGNITES THE CORE AND PUSHES A SHELL OUT THROUGH THE BODY on the sweep
// -- the light arrives at the surface, lifts the rim, and settles. The interior
// ignites and settles, which is the family's law, said in the physics of a drop.
//
// SPREAD (c3, default 0.3) rides DEPTH here: content nearer the viewer takes one
// hue and content further takes the other, so the core seen through the front of
// the glass is a hair warmer than the same core's halo behind it. That is what
// dispersion looks like when it is behaving, and at 0.3 it is felt rather than
// seen.
//
// SIZE: at 18 pt the deformation is turned UP by a fifth (a small body needs a
// louder silhouette to read as anything but a circle), the tremor is off, and
// the core grows to nearly half the body so what survives is one clear gesture:
// a wobbling drop with a light in it.
[[ stitchable ]] half4 mh_droplet(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float wobbleK  = clamp(c0, 0.0, 1.0);   // how far out of round
    float tensionK = clamp(c1, 0.0, 1.0);   // how tightly it holds its shape
    float sheenK   = clamp(c2, 0.0, 1.0);   // the surface's light
    float spreadK  = clamp(c3, 0.0, 1.0);   // dispersion through the depth

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    // THE INHALE. The breath is the carrier and voice is what fills it, so the
    // swell arrives on a curve. Capped at 0.05: with the 0.085 deformation cap
    // on top, the worst-case silhouette is 0.300 * 1.05 * 1.085 = 0.339 uv, and
    // the containment does not begin until 0.36.
    float br = mh_breath(t, 0.9);
    float swell = (0.22 + 0.78 * br) * live.voice;
    float bodyScale = 1.0 + 0.050 * swell;

    // Higher tension means a body that holds its shape: the knob runs backwards
    // through the amplitude on purpose, because that is what tension IS.
    float wob = (0.052 + 0.040 * wobbleK) * (1.0 - 0.22 * tensionK)
              * (1.0 + 0.30 * swell) * mix(1.0, 1.20, small);

    float tremGate = mh_aa(6.2831853 * 6.9 / MH_R, size, pixelScale) * (1.0 - small);
    MHShape sh = mh_shape(wob, 0.012 * live.pace * tremGate, 3.30);

    // RESPONDING: the wobble acquires a heading.
    if (st.drive > 0.002) {
        sh.flowDir = normalize(float3(0.92, 0.20, 0.34));
        sh.flowAmp = 0.30 * st.drive;
        sh.flowPhase = -mh_drift(t, 2.05, 0.30, 7.0);
    }

    MHBody b = mh_body(uv / bodyScale, t, px / bodyScale, sh);
    // The membership and radii above were solved in the swollen body's own
    // units, which is exactly what we want everywhere except the contact glow's
    // in-plane radius -- and that is handled by mh_surface reading b.rho, which
    // is in the same units. Nothing else needs unscaling.

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_refract(V, b.N, MH_ETA);
    float L = mh_exit(b.P, rd);

    // THE HEART IS COMPOSED, NOT ACCIDENTAL, and round one had it the other way
    // round on both counts.
    //
    // IT IS CENTRED. The lag was a tenth of the radius on three axes, which
    // meant the core was never in the middle and its position was a function of
    // three sines nobody could predict: a light wandering around inside a ball
    // rather than the ball's own heart. It is down to 0.028 -- a whisper, enough
    // that the core is never nailed to the exact centre and the drop still reads
    // as liquid carrying its contents a beat behind, and far too little to read
    // as off-centre. Composition beats incident here; there is one thing in this
    // glass and it belongs in the middle of it.
    //
    // IT IS ROUND, and that took solving it rather than sampling it. A core
    // 0.22 body units across, marched at steps of about 0.38, was caught by one
    // tap or two depending on where the planes happened to fall along a
    // refracted ray whose direction changes every pixel -- so the shape the eye
    // got was the shape of the SAMPLING, and it read as a smear. Evaluated at
    // the ray's closest approach it is two dot products, exact at every
    // distance, and a sphere seen from any angle is a disc. The refraction is
    // still fully in it, because the closest approach is measured along the
    // REFRACTED ray: the heart still displaces and swells as the wobbling
    // surface lenses it, which is the whole reason the interior is kept clear.
    //
    // IT BREATHES. Voice grows the heart and brightens it on the same eased
    // swell that inflates the body, so the inhale is one gesture the whole drop
    // makes rather than two things that happen to correlate.
    float3 coreC = float3(0.028 * sin(t * 0.213 + 0.6),
                          0.026 * sin(t * 0.167 + 2.4),
                          0.024 * sin(t * 0.139 + 4.1));
    // THE CORE IS SMALL. It has to be: the interior is briefed as nearly clear,
    // and a core that fills the body is not a light inside glass, it is a lamp
    // with a shade. At a quarter of the radius the core occupies a sixtieth of
    // the body's volume, which leaves the rest for the refraction to be visible
    // in -- and the refraction is the species.
    float coreR = (0.17 + 0.10 * (1.0 - tensionK)) * S
                * mix(1.0, 1.55, small) * (1.0 + 0.22 * swell);
    float coreBright = 1.0 + 0.85 * live.voice + 0.35 * st.settled;

    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        // SUCCESS: a shell of light leaves the heart and reaches the surface. It
        // is a TRAVELLING term only -- the first cut added a flat lift alongside
        // it and success rendered as a solid white disc, which is precisely the
        // white overlay the family law forbids. This stays in the march because
        // it is a moving front through the volume rather than a compact object,
        // which is exactly the thing five taps are good at.
        float shell = 0.0;
        if (st.complete > 0.001) {
            float sr = (length(p) - mix(0.05, 1.0, st.sweep)) / 0.20;
            shell = st.complete * 0.34 * exp(-sr * sr);
        }

        float med = mh_medium(p, t, 2.1 / S) * 0.090;
        float e = (shell + med) * fade;

        acc.x += e * trans * ds;
        // Depth carries the dispersion: the near half of the ray one way, the
        // far half the other. p.z is the body's own depth, +1 toward the viewer.
        acc.y += e * fade * clamp(p.z, -1.0, 1.0) * trans * ds;
        trans *= exp(-(2.40 * e + MH_EXT) * ds);
    }

    // THE HEART, at the ray's closest approach, plus the light it throws into the
    // glass around it. The scatter is what stops a clear interior reading as an
    // empty one: the heart lights the fog it sits in, the fog dims with depth
    // because MH_EXT is in the visibility term, and the drop comes out as a lamp
    // inside a lens instead of a disc pasted on ink.
    float3 toC = coreC - b.P;
    float sC = dot(toC, rd);
    float heart = 0.0;
    if (sC > 0.0 && sC < L) {
        float dC2 = max(dot(toC, toC) - sC * sC, 0.0) / max(coreR * coreR, 1e-6);
        float vis = mh_inside(b.P + rd * sC) * exp(-MH_EXT * sC) * coreBright;
        heart = (exp(-dC2) * 1.65 + mh_scatter(dC2, 0.34)) * vis
              * (1.0 + 0.26 * st.complete);
    }

    float interior = (acc.x * 4.20 + heart) * b.m * mh_transmit(b.fres);
    float hue = (acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD;

    // The sheen knob is this hero's: a wobbling surface is only visibly wobbling
    // if there is a highlight riding it, so droplet spends more of its energy on
    // the specular than any other hero does.
    MHSurface sf = mh_surface(b, t, small,
                              1.05 + 0.55 * sheenK + 0.35 * live.voice,
                              0.42 + 0.30 * sheenK,
                              0.16);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.6) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, hueShift, depth);
    return mh_present(e, hueMix, uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 3. Limn

// LIMN. Near-dark glass whose EDGE is alive.
//
// THE SPECIES IS A NEGATIVE. Every other hero fills the volume and lets the rim
// finish it; this one empties the volume almost completely and puts everything
// into a single travelling arc of light on the silhouette. It exists because a
// collection of twelve luminous bodies needs one that is mostly dark -- on a
// gallery wall it is the one your eye goes to second and stays on, and in a chat
// UI it is the one that does not compete with the text.
//
// NEVER A FULL EVEN RING. That is the whole brief and it is enforced by the
// arc's profile: an ASYMMETRIC gaussian in the angle, tight ahead of the head
// (0.42 rad) and long behind it (1.15 rad), so what travels is a comma of light
// with a soft tail rather than a dot or a ring. The two halves meet at the peak
// where both slopes are zero, so the join is C1 and invisible. The tail is short
// enough that it has decayed to nothing by the time it wraps to pi, which is
// what keeps the arc from ever quietly becoming the ring it must not be.
//
// THE TRAVEL IS EASED, hard. mh_drift with a wobble of 0.62 means the arc
// hurries through part of its lap and dawdles through the rest -- a light going
// somewhere, not a light going round. At a constant rate this species was a
// spinner and nothing else.
//
// LEVEL THICKENS AND BRIGHTENS IT. Voice widens the radial band the arc lives
// in (up by 80 per cent), widens the head, and lifts the whole thing. A quiet
// room gets a thin bright scratch of light; a person talking gets a broad warm
// blade of it. That is the deepest reading of `level` in this batch and it is
// why this hero is here.
//
// ACTIVITY QUICKENS THE TRAVEL, and only that. Cadence is the rate of a stream
// and the arc's rate is the honest place to spend it.
//
// THE INTERIOR HOLDS ONLY A HINT of what the rim illuminates. The arc's position
// is a direction in three dimensions, so the inside of the glass glows faintly
// where that light would have entered: a dot product against the sample's own
// direction, cubed. It costs one line and it is the difference between a rim
// drawn ON a dark disc and a rim lighting a dark VOLUME.
//
// RESPONDING: the arc stops wandering. The eased travel flattens toward
// constant, the rate roughly doubles, and the tail stretches -- decisive, a
// single sustained sweep instead of a searching one.
//
// SUCCESS: the arc completes a full lap on the sweep and, at the moment of
// arrival, the rim briefly closes into the even ring it is otherwise never
// allowed to be. The presence's pattern is an incomplete circle; completing it
// is closing the circle. Then it opens again and settles brighter.
//
// SIZE: at 18 pt the head widens from 0.42 to 1.05 rad and the band thickens
// nearly threefold -- 0.09 body units is half a pixel at 18 pt -- so what
// survives is one broad comma of light sweeping a dark bead. The interior hint
// drops to almost nothing, because at 18 pt there is no interior to hint at.
[[ stitchable ]] half4 mh_limn(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float widthK  = clamp(c0, 0.0, 1.0);   // how thick the rim band is
    float travelK = clamp(c1, 0.0, 1.0);   // how fast the arc goes round
    float hintK   = clamp(c2, 0.0, 1.0);   // how much reaches the interior
    float spreadK = clamp(c3, 0.0, 1.0);   // the tail's hue drift

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    // The body is barely out of round and its shading gain is low: this hero's
    // rim is a designed shape and a lively normal would fight it for the same
    // pixels.
    MHShape sh = mh_shape(0.020, 0.0, 1.05);
    MHBody b = mh_body(uv, t, px, sh);

    // THE ARC'S POSITION. Responding flattens the easing toward constant and
    // roughly doubles the rate: a decisive sweep.
    float wobble = mix(0.62, 0.14, st.drive);
    float rate = (0.34 + 0.40 * travelK)
               * (1.0 + 0.95 * live.pace + 0.30 * live.voice) * (1.0 + 1.05 * st.drive);
    float phi0 = mh_drift(t, rate, wobble, 1.0);

    // SUCCESS drives one full extra lap on the sweep, so the ignition travels
    // rather than flashing in place. `sweep` is zero outside the state and the
    // whole term is read modulo a turn, so entering and leaving are both
    // invisible.
    phi0 += st.sweep * 6.2831853;

    float phi = atan2(uv.y, uv.x);
    float aw = phi - phi0;
    aw = aw - 6.2831853 * floor(aw / 6.2831853 + 0.5);      // wrapped to -pi...pi

    // THE COMMA, AND IT MUST CLOSE. The first cut built the asymmetry the
    // obvious way -- one gaussian in the angle with a narrow width ahead of the
    // head and a wide one behind -- and it left a razor-thin dark seam down one
    // radius of the body, visible at every size and unmissable at 18 pt with
    // somebody talking. The reason is that the two halves do not agree where the
    // wrap happens: at plus and minus pi the narrow side had fallen to 0.03 and
    // the wide side was still at 0.21, so the field simply steps. A gaussian in
    // a wrapped angle is not a periodic function and no amount of tuning makes
    // it one; the argument is the same one mq_ring_noise makes about reading
    // noise in the polar angle, arriving from the other direction.
    //
    // So the comma is built from two von Mises bumps instead, which ARE periodic
    // by construction because they are functions of cos(angle) alone. A tight
    // one at the head, and a broad one offset about a radian BEHIND it at half
    // the amplitude. Their sum is the same shape the eye wanted -- a bright head
    // with a soft tail streaming off one side -- and it is seamless everywhere.
    //
    // The concentrations are set by what happens on the OPPOSITE side of the
    // ring, because "never a full even ring" is this species' whole brief: at
    // 120 pt the far side sits at four per cent of the peak and at 18 pt, where
    // the whole gesture has to be much broader to be legible at all, it reaches
    // eleven. Eleven per cent is a dim glow opposite a bright arc. It is not a
    // ring, and the number was chosen by looking at where it started to become
    // one.
    float kHead = mix(9.0, 2.2, small) / (1.0 + 0.60 * live.voice);
    float kTail = mix(1.6, 0.95, small) / (1.0 + 0.35 * live.voice + 0.30 * st.drive);
    float offT  = mix(-1.05, -1.25, small) - 0.30 * st.drive;
    float headLobe = exp(kHead * (cos(aw) - 1.0));
    float tailLobe = exp(kTail * (cos(aw - offT) - 1.0));
    float arc = headLobe + 0.52 * tailLobe;

    // THE BAND. Where the light sits radially: just inside the silhouette, and
    // thickening with voice. 0.09 body units is about four pixels at 120 pt.
    // THE BAND HAS A CEILING, and it needs one. Three multipliers stack here --
    // the width knob, voice, and the small mount -- and at 18 pt with somebody
    // talking they multiplied out to a "band" wider than the body's radius. What
    // that draws is not a thickened rim: it is a solid wedge of light reaching
    // the middle of the sphere, with the arc's angular profile as its boundary,
    // and an angular profile read at that radius is a nearly straight line. A
    // hard edge on an organic form is the one thing this house never ships. The
    // cap at 0.30 body units keeps it a band at every combination of dials.
    float bw = min((0.070 + 0.055 * widthK) * (1.0 + 0.55 * live.voice)
                   * mix(1.0, 2.10, small) * S, 0.30);
    float dband = (b.rho - b.Rd * 0.965) / max(bw, 1e-3);
    float band = exp(-dband * dband) * b.m;

    // Fresnel keeps the light physically ON the edge rather than merely near it,
    // so the arc bends around the body's curvature instead of lying flat.
    float rimlight = band * (0.30 + 0.70 * pow(b.fres, 1.6));

    // SUCCESS CLOSES THE CIRCLE, once, for a breath. This is the only frame in
    // the species where a full even ring is correct: it is the pattern being
    // completed, and it opens again immediately.
    float ringClose = st.complete * band * 1.20;

    // The small mount lifts the arc by a third: the band is nearly three times
    // wider down there, so the same energy spread over three times the area
    // stopped reaching the rail's specular stop at all, and an 18 pt limn had no
    // cream in it anywhere. Wider AND brighter is what keeps the hierarchy.
    float rimE = rimlight * arc * (1.70 + 1.15 * live.voice) * mix(1.0, 1.15, small)
               * (1.0 + 1.6 * st.complete) * (1.0 + 0.30 * st.settled)
               + ringClose;

    // THE INTERIOR HINT. The arc as a direction in three dimensions; the volume
    // glows faintly where that light entered.
    float3 arcDir = float3(cos(phi0), sin(phi0), 0.0);
    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_refract(V, b.N, MH_ETA);
    float L = mh_exit(b.P, rd);

    float hintAmt = (0.22 + 0.38 * hintK) * (1.0 + 0.9 * live.voice)
                  * mix(1.0, 0.28, small);

    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        // The hint is strongest just under the arc and dies toward the middle,
        // because light entering a dark medium does not reach the far side. The
        // exponent came down from 3 to 2.2 on the round-one note that the rim
        // may bleed a whisper more inward: a lower power is a wider wash, so the
        // arc's light reaches further around the body's own curve.
        float lit = pow(clamp(dot(normalize(p + 1e-5), arcDir), 0.0, 1.0), 2.2);
        float reach = smoothstep(0.10, 0.85, length(p));
        float haze = mh_haze(p, t, 2.4 / S) * 0.55 + 0.45;

        // Even the dark hero gets a floor. Limn is meant to read as near-black
        // GLASS and not as a hole in the frame, and at 0.030 -- a third of what
        // the luminous heroes carry -- there is just enough fog for the far wall
        // to exist.
        float e = (lit * reach * haze * hintAmt + mh_medium(p, t, 2.4 / S) * 0.030) * fade;
        acc.x += e * trans * ds;
        acc.y += e * fade * trans * ds;
        trans *= exp(-(1.80 * e + MH_EXT) * ds);
    }

    float interior = acc.x * 3.00 * b.m * mh_transmit(b.fres) * (1.0 + 0.9 * st.complete);

    // SPREAD rides the tail: the head sits on the anchor hue and the light
    // behind it drifts toward a neighbour as it cools, which is what a trailing
    // light does. The weight is the TAIL LOBE'S OWN SHARE of the light at this
    // pixel, which is both the honest measure of "how much of what I am seeing
    // here is old light" and, unlike the wrapped angle the first cut used,
    // periodic -- so the hue has no seam either.
    float tailShare = 0.52 * tailLobe / max(headLobe + 0.52 * tailLobe, 1e-4);
    float hue = -tailShare * spreadK * MH_SPREAD;

    // THE SPHERE HAS TO BE THERE WHEN THE ARC IS NOT. The first cut set the base
    // rim near zero on the argument that a second rim would fill in the dark
    // half and turn the comma back into a ring, and it did avoid that -- and
    // produced a crescent moon rather than a dark glass body with a lit edge.
    // 0.30 is the fitted middle: enough that the silhouette closes all the way
    // round and the eye reads a sphere, far too little to compete with the arc,
    // which runs four times brighter than it does.
    MHSurface sf = mh_surface(b, t, small, 0.30, 0.78 + 0.35 * live.voice, 0.09);

    float e = interior + rimE + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (rimE + interior) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, hueShift, depth);
    return mh_present(e, hueMix, uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 4. Comet

// COMET. One bright point on a tilted orbit inside the glass, trailing light.
//
// THE TRAIL IS NOT A HISTORY BUFFER. The obvious build -- remember where the
// point was and smear it -- is impossible here, because these shaders are
// stateless by contract: any `time` has to render the correct frame or the
// screenshot rig and the scrub slider disagree with the app. So the trail is
// solved geometrically instead, and it is the nicest piece of arithmetic in the
// file. The orbit is a circle in a plane, so for any point in the volume the
// NEAREST POINT ON THAT CIRCLE is closed form: project into the plane's basis,
// pull the in-plane component out to the orbit radius, and the leftover is the
// distance to the tube. The angle of that nearest point, subtracted from the
// head's angle and wrapped, is exactly how long ago the head was there. Trail
// brightness is then a decay in that age. The result is a trail that follows the
// orbit's curvature perfectly, costs four dot products, and is correct at any
// time value including ones the app never rendered.
//
// THE ORBIT IS TILTED AND PRECESSES, which is the reason this hero is in the
// collection: the point goes BEHIND the core of the glass and comes back around
// the front, and the interior march makes that legible as depth because the
// haze in front of it dims it. A flat orbit would be a circle drawn on a disc
// and the species would be worthless.
//
// LEVEL SWELLS THE POINT'S LIGHT. Voice grows the head and its halo and lifts
// its brightness -- the point gets fatter and hotter, not faster. Speed is
// cadence's job, and keeping the two signals on different axes is what lets a
// person read which one is happening.
//
// ACTIVITY TIGHTENS THE ORBIT. Cadence pulls the radius in by up to a quarter
// and quickens the travel: a busy assistant's thought circles closer and faster.
// The two together read as winding up, which is the right feeling for a token
// stream.
//
// RESPONDING STRETCHES THE TRAIL toward a full ring and drives the rate up: the
// point stops being a spark going round and becomes a streak with a head, which
// is what "answering now" looks like in this grammar.
//
// SUCCESS IGNITES THE WHOLE ORBIT along the sweep -- the trail fills in behind
// the head all the way round, the head flares, and it settles back to a brighter
// spark. The ignition travels, which is the family law.
//
// SPREAD (c3, default 0.3) rides the trail's AGE: the head is the anchor hue and
// the trail cools toward a neighbour as it fades. It is the most literal use of
// the knob in this batch and the most legible.
//
// SIZE: at 18 pt the orbit radius grows from 0.54 to 0.66 of the body (a small
// orbit inside a small body is a jitter, not a circling), the head grows by
// half, the trail SHORTENS to about a third of a lap, and the fog drops by half
// so the spark keeps the contrast to be seen at all. What survives is exactly
// the brief: a clean spark circling.
[[ stitchable ]] half4 mh_comet(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float tiltK   = clamp(c0, 0.0, 1.0);   // how far the orbit leans
    float trailK  = clamp(c1, 0.0, 1.0);   // how long the tail is
    float pointK  = clamp(c2, 0.0, 1.0);   // how big the head is
    float spreadK = clamp(c3, 0.0, 1.0);   // the trail's hue drift

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.024, 0.0, 1.30);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_refract(V, b.N, MH_ETA);
    float L = mh_exit(b.P, rd);

    // THE ORBIT PLANE. A tilt about x, then a slow eased precession about y, so
    // the plane's edge-on moment never lands twice in the same place and the
    // point's path is never quite the ellipse it was a minute ago. The tilt is
    // bounded away from both failures: face-on is a circle drawn on the glass,
    // edge-on is a line.
    float tau = mix(0.30, 1.05, tiltK);
    float prec = mh_drift(t, 0.070, 0.45, 2.0);
    float3 e1 = mh_spin(float3(1.0, 0.0, 0.0), prec, 0.0);
    float3 e2 = mh_spin(float3(0.0, sin(tau), cos(tau)), prec, 0.0);

    // Radius: pulled in by cadence, pushed out at small size so the circling is
    // parseable rather than a jitter in the middle.
    float r0 = mix(0.54, 0.66, small) * (1.0 - 0.24 * live.pace) * S;
    r0 = clamp(r0, 0.20, 0.70);

    // One lap in about six seconds at rest: slow enough to watch, fast enough
    // that the point is unambiguously travelling rather than drifting.
    float rate = 1.05 * (1.0 + 0.85 * live.pace + 0.95 * st.drive);
    float psi = mh_drift(t, rate, 0.38, 3.0);

    float3 head = r0 * (cos(psi) * e1 + sin(psi) * e2);

    // Head width. 0.040 body units is about three pixels at 120 pt; at 18 pt it
    // grows by half, which is about a pixel and a half -- a spark that is still
    // a spark rather than a stipple. The first cut ran at 0.086 and the
    // head was a soft blob half the size of the core it was supposed to be
    // orbiting inside: a point of light has to be a POINT or the trail behind
    // it has nothing to have come from.
    float hw = (0.028 + 0.030 * pointK) * (1.0 + 0.45 * live.voice)
             * mix(1.0, 1.55, small) * S;
    // The tail is WIDER than the nucleus, which is both true of comets and
    // necessary here: the trail is still sampled by the five taps, and a tube
    // thinner than the step would alias the way the head did. 1.9 times the head
    // puts it at about 0.08 body units, which two adjacent taps can resolve.
    float tubeW = hw * 1.45;

    // Trail decay, in radians of age. The small mount SHORTENS it -- a full lap
    // of trail inside an 18 pt bead is a ring, and a ring is the wrong species.
    // LONGER, and the round-one note was right that it needed to be: at 1.22
    // radians the trail had faded out barely a fifth of the way round and read
    // as a smudge behind the head rather than as a path the point had come
    // along. At 2.0 it carries most of a half-turn, which is enough arc for the
    // eye to see it CURVE -- and a trail that curves is the only proof on offer
    // that the orbit is a circle in three dimensions rather than a streak.
    float decay = (1.30 + 2.60 * trailK) * (1.0 + 1.25 * st.drive)
                * mix(1.0, 0.40, small);
    if (st.complete > 0.001) {
        // SUCCESS: the orbit fills in behind the head, out to wherever the sweep
        // has reached, so the ignition runs the length of the path.
        decay = mix(decay, 9.0, st.sweep);
    }

    float headBright = (1.0 + 1.30 * live.voice) * (1.0 + 2.2 * st.complete)
                     * (1.0 + 0.25 * st.settled);
    // The dark hero of the luminous three: comet needs contrast around its point
    // more than it needs a filled body, so its fog runs at two thirds of aura's.
    float medAmt = mix(0.055, 0.028, small);
    float3 nrm = cross(e1, e2);

    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        // THE NEAREST POINT ON THE ORBIT, in closed form.
        float u = dot(p, e1), v = dot(p, e2);
        float w = dot(p, nrm);
        float q = sqrt(u * u + v * v);
        float dq = q - r0;
        float dist2 = dq * dq + w * w;

        // ...and how long ago the head was there. SIGNED, into -pi...pi, where
        // positive is behind the head and negative is the short arc ahead of it.
        float psiP = atan2(v, u);
        float age = psi - psiP;
        age = age - 6.2831853 * floor(age / 6.2831853 + 0.5);   // -pi ... pi

        // THE TRAIL HAS TO DIE BEFORE IT WRAPS, and lengthening it is what
        // exposed that. At the old decay of 1.2 radians the trail was down to
        // half a per cent by the time it came round to meet its own head, and
        // the step where it did was invisible. At 2.0 it is still at a fifth --
        // and the scatter halo, which reaches three times the tube's width in
        // every direction, carried that step out into a wide swath. What drew
        // was a hard-edged wedge cut through the glass along the head's own
        // radius. Two soft gradients meeting is a gradient; a soft gradient
        // meeting a step is the step.
        //
        // So the fall is explicitly taken to zero at BOTH ends of the wrapped
        // interval: an exponential behind the head, faded out over the last
        // stretch before pi, and a short exponential coma ahead of it that is
        // also gone by -pi. Both sides are zero where they meet, so the field is
        // continuous all the way round. They meet again at the head itself at a
        // value of one, with a kink rather than a step -- and that kink sits
        // under the head's own bloom, which is where a comet keeps it too.
        float fall;
        if (age >= 0.0) {
            fall = exp(-age / max(decay, 1e-3)) * (1.0 - smoothstep(2.30, 3.1416, age));
        } else {
            fall = exp(age / 0.30);
        }

        // The trail and the glow it throws into the glass, on one argument.
        float targ = dist2 / (tubeW * tubeW);
        float trail = (exp(-targ) + mh_scatter(targ, 0.22)) * fall;

        float med = mh_medium(p, t, 2.3 / S) * medAmt;
        float e = (trail * 1.55 + med) * fade;

        acc.x += e * trans * ds;
        // The hue rides the trail's age: the head true, the tail drifting to a
        // neighbour.
        acc.y += trail * 1.55 * fade * clamp(age / 3.1416, 0.0, 1.0) * trans * ds;
        trans *= exp(-(4.20 * e + MH_EXT) * ds);
    }

    float interior = acc.x * 4.20 * b.m * mh_transmit(b.fres) * (1.0 + 0.20 * st.settled);
    float hue = -(acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD * 1.4;

    // THE HEAD IS SOLVED, NOT SAMPLED, and this is the one place in the file
    // where five taps were not enough. The head is 0.043 body units across and
    // the march steps about 0.38, so whether a ray caught it at all depended on
    // where the tap planes happened to fall: the point flickered as it moved,
    // and near the limb, where the refracted ray is long and the ghost image
    // lives, it rendered as a SECOND comet. A species whose whole brief is one
    // bright point cannot have two.
    //
    // So the head comes out of the loop and is evaluated at the ray's closest
    // approach to it, which for a straight ray and a point is two dot products.
    // That is exact at every distance, costs a twentieth of what raising the tap
    // count would, and cannot alias in depth because there is no sampling left
    // in it. `sH` is how far into the glass the closest approach is, so
    // exp(-MH_EXT * sH) dims the head when it is on the far side of its orbit --
    // which is the depth cue that tells you the point went BEHIND the middle,
    // and is also what puts the limb ghost back down where it belongs.
    float3 toH = head - b.P;
    float sH = dot(toH, rd);
    float dH2 = max(dot(toH, toH) - sH * sH, 0.0);
    float headE = 0.0;
    if (sH > 0.0 && sH < L) {
        float harg = dH2 / (hw * hw);
        float vis = mh_inside(b.P + rd * sH) * exp(-MH_EXT * sH) * mh_transmit(b.fres);
        // A SOFTER POINT THAT BLOOMS. Round one drove the narrow term to 1.55,
        // and a gaussian whose peak is that far above the rail's knee is flat
        // over most of its width: the tier map has nothing left to grade with,
        // so what draws is a disc of constant cream with a step at its rim. It
        // read as pasted on, which it effectively was. At 0.92 the peak lands
        // just into cream and the shoulders keep their gradient, and the light
        // that used to be in the core is spent instead on the scatter -- ten
        // times the area, blooming into the medium, dimming with depth because
        // MH_EXT is in `vis`. Same total light; a point of it now, instead of a
        // sticker.
        headE = (exp(-harg) * 0.92 + mh_scatter(harg, 0.30)) * headBright * vis * b.m;
    }

    // NOTHING ELSE IN THE GLASS. The specular is on the SHELL rather than in the
    // volume, but at 0.40 it was landing as a second warm light a third of the
    // way in from the rim and reading as a stray artifact next to a species
    // whose entire brief is one point. At 0.22 it is a catchlight: the glass
    // still says it is glass, and there is only one thing in it.
    MHSurface sf = mh_surface(b, t, small, 0.80 + 0.35 * live.voice, 0.22, 0.15);

    float e = interior + headE + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, hueShift, depth);
    return mh_present(e, hueMix, uv, pal, glow, inkColor, position, pixelScale);
}
