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
//   mh_nebula   the volumetric showcase: no object at all, just weather. Mist
//               folding slowly, lit from within so near folds silhouette
//               against the deep glow, with a glint buried in it.
//   mh_prism    light entering where the highlight says it does and fanning
//               into three soft diverging shafts, one hue each.
//   mh_duet     two luminous bodies orbiting a common centre, one warm of the
//               anchor and one cool, passing in front of and behind each other.
//   mh_still    the discipline piece: a nearly clear sphere whose rim and
//               catchlight are the figure, crossed by one slow glint.
//   mh_fathom   nested translucent shells, solved rather than marched, each
//               folded and turning at its own rate: depth you can count.
//   mh_arc      one soft bright filament arcing through the volume, anchored
//               near the core and never touching the shell.
//   mh_opal     play-of-colour: four soft flashes born and absorbed slowly, at
//               four points across the widest spread in the collection.
//   mh_flux     an aurora streaming inside the glass: curtains standing on a
//               bright foot, bending as they go.
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
// PLAY, AND WHERE IT LIVES. From the second batch on every hero performs one
// gesture: a thing the presence does now and then and then lets go of. Nebula
// buries a glint in its weather, prism's fan opens wider than it otherwise ever
// does and sends a pulse down the shafts, duet's pair draws close and hurries
// once around each other, and still's single crossing glint IS its whole
// species. mh_flourish times them -- slots with a hashed onset inside each, so
// the gaps are never equal and there is nothing for the eye to count -- and it
// is deterministic, because a gesture that depends on when the app happened to
// start is a gesture the screenshot rig cannot reproduce.
//
// TWO GROUNDS, ONE FAMILY. The shader is handed the ground it will sit on, and
// on a light one nearly every rule above turns over. There is nowhere brighter
// than paper for energy to go, so the rail descends instead of climbing: content
// becomes CHROMA AND SHADOW rather than light, which is what a tinted
// transparent object actually does to what is behind it. The body goes pale
// -- clear glass on a page is almost nothing plus an edge -- the rim becomes the
// fine dark refracted edge rather than a glow, the contact bloom becomes a
// contact shadow pooled beneath, and the specular leaves the energy sum
// altogether to be composited as the one thing in the frame brighter than the
// page. mh_paper reads the ground's OKLAB lightness and everything downstream
// MIXES on it rather than branching, so a mid grey lands somewhere both rails
// agree on and a designer dragging the ink from ink to paper never sees a jump.
// At paper = 0 every one of those terms is algebraically the identity, which is
// how the twelve heroes reviewed on ink are unchanged to the bit.
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

/// HOW LIGHT THE GROUND IS, in OKLAB lightness rather than an RGB average,
/// because a saturated mid-blue paper and a light grey with the same channel
/// mean are nowhere near the same brightness to the eye and this decision is
/// entirely about what the eye does.
///
/// Returns 0 for the house ink (L about 0.16), 1 for paper (L about 0.97), and
/// a continuous blend between. The band is placed so a true mid grey -- sRGB
/// 0.5, whose OKLAB L is 0.60, not 0.5 -- lands at about four tenths of the way
/// across, which is the honest answer for a ground that is genuinely ambiguous.
/// Nothing in this file ever branches on it; every use is a mix, so a designer
/// dragging the ink colour from ink to paper sees the body change continuously
/// with no frame where it jumps.
static inline float mh_paper(half4 inkColor) {
    float L = mh_linear_to_oklab(mh_srgb_to_linear(float3(inkColor.rgb))).x;
    return smoothstep(0.50, 0.72, L);
}

/// Four OKLAB stops built from one anchor: the tone the indicator wears.
/// Ordered dark to bright on an ink ground, PALE TO DEEP on a paper one, and
/// mixed between the two by how light the ground is. Never more than one hue
/// family wide either way.
struct MHPalette {
    float3 s0, s1, s2, s3;
    float  paper;   // how light the ground is, 0 ink ... 1 paper
    float  duo;     // how far tone2 is from tone, 0 when identical
    float  dHue;    // tone2's hue minus tone's, the short way round
    float  dC;      // tone2's chroma over tone's
    float  dL;      // tone2's lightness over tone's
};

/// s0 is the ink the whole app sits on, so a field at zero dissolves into the
/// screen with no seam. s1 is a deep shadow that KEEPS the tone's hue at half
/// its chroma, which is what stops the dark end going grey. s2 is the tone. s3
/// is a pale specular a few degrees warmer, because light that has passed
/// through anything comes out warmer than the thing it lit.
/// `depth` opens the range from both ends without letting the hue wander.
static MHPalette mh_palette(half4 inkColor, half4 toneColor, half4 tone2Color,
                            float hueShift, float depth) {
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
    p.paper = mh_paper(inkColor);

    // THE SECOND ANCHOR. Read as a DIFFERENCE from the first rather than as a
    // palette of its own, which is what keeps duotone inside the family's one
    // law: the rail is still built entirely from `tone`, and tone2 only says
    // where the spread's positive side is allowed to walk to. A configuration
    // with two anchors is still one material lit two ways, not two materials.
    //
    // `duo` is a smoothstep on the OKLAB distance between the anchors and it is
    // EXACTLY ZERO when they are equal, which is the property the whole upgrade
    // rests on: at zero every term below collapses to the identity and the
    // twelve heroes already reviewed render bit for bit as they did.
    //
    // The hue difference is taken the SHORT way round the wheel. Without the
    // wrap, two anchors either side of the origin -- a red and a warm yellow,
    // say -- would walk the long way through green to reach each other, which is
    // both wrong and the one thing the one-hue-family rule exists to prevent.
    float3 tone2 = mh_linear_to_oklab(mh_srgb_to_linear(float3(tone2Color.rgb)));
    float C2 = length(tone2.yz);
    float h2 = atan2(tone2.z, tone2.y) + hueShift;
    float dh = h2 - (atan2(tone.z, tone.y) + hueShift);
    p.dHue = dh - 6.2831853 * floor(dh / 6.2831853 + 0.5);
    p.dC   = C2 / max(length(tone.yz), 1e-4);
    p.dL   = tone2.x / max(tone.x, 1e-4);
    p.duo  = smoothstep(0.004, 0.035, length(tone2 - tone));

    // THE INK RAIL. Dark to bright: energy becomes light.
    float3 d0 = ink;
    float3 d1 = mh_lch(mix(ink.x, L, 0.30 / d), C * (0.52 + 0.10 * d), h - 0.35);
    float3 d2 = mh_lch(L, C, h);
    float3 d3 = mh_lch(min(L * (1.20 + 0.12 * d), 0.93), C * 0.55, h + 0.10);

    // THE PAPER RAIL, and it runs the other way, because on a light ground
    // energy cannot become light -- there is nowhere brighter than the paper to
    // go. Kris's note was that the defaults are hard on light mode, and this is
    // the whole of why: the ink rail's top stop is a pale cream at L 0.93, which
    // against paper at L 0.97 is invisible. A cream rim on white is not a dim
    // rim, it is no rim.
    //
    // So on paper the rail descends and DEEPENS. Energy becomes chroma and
    // shadow, which is what a tinted transparent object actually does to the
    // light behind it: more material, more colour, less transmitted light.
    //
    //   l0  the paper itself, so a field at zero dissolves into the page with no
    //       seam -- the same law s0 obeys, said on the other side.
    //   l1  THE GLASS. Barely off the paper and barely tinted, because that is
    //       what a clear sphere on white looks like: almost nothing, plus an
    //       edge. This stop is most of the body and it is meant to be.
    //   l2  the tone, dropped in lightness and pushed a fifth up in chroma. This
    //       is where interior CONTENT lands, and the chroma is what carries the
    //       read now that lightness cannot.
    //   l3  the deepest, for the rim's refracted edge and the hottest spines:
    //       darker still and shifted a little toward ember, because looking
    //       through more of a warm glass is what makes it go red rather than
    //       what makes it go pale.
    //
    // Chroma above the sRGB gamut clips in mh_out. The multipliers are kept near
    // 1.2 for that reason: the house amber sits around 0.11 OKLAB chroma, so a
    // fifth over is still inside the gamut and no hue twists on the way out.
    float Lp = ink.x;
    float3 l0 = ink;
    float3 l1 = mh_lch(mix(Lp, L, 0.42 / d), C * (0.34 + 0.10 * d), h + 0.05);
    float3 l2 = mh_lch(L * (0.82 - 0.06 * d), C * (1.20 + 0.14 * d), h);
    float3 l3 = mh_lch(max(L * (0.52 - 0.05 * d), 0.18), C * (1.05 + 0.10 * d), h - 0.08);

    // MIXING THE STOPS RATHER THAN THE COLOURS, and it is exact rather than an
    // approximation: mh_shade's walk is linear in the stops for any fixed t, so
    // blending the stops first and walking once gives the identical answer to
    // walking both rails and blending the results -- at half the cost, and with
    // the guarantee that a mid-grey ground can never land somewhere neither rail
    // would have gone.
    p.s0 = mix(d0, l0, p.paper);
    p.s1 = mix(d1, l1, p.paper);
    p.s2 = mix(d2, l2, p.paper);
    p.s3 = mix(d3, l3, p.paper);
    return p;
}

/// The spread cap. 0.50 radians is about 29 degrees of OKLAB hue either side of
/// the anchor: amber to gold one way, amber to ember the other. Two or three
/// hues in conversation, which is the reference-orb look, and nowhere near a
/// second hue family, which is the rule.
constant float MH_SPREAD = 0.50;

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
    // THE SPREAD AXIS, AND DUOTONE RIDES IT. `hue` is a signed offset along the
    // spread: negative is one neighbour of the anchor, positive the other. With
    // one anchor both sides are the same rotation mirrored, which is what the
    // twelve heroes were built on. With two, the POSITIVE side stops being a
    // rotation of the anchor and becomes a walk toward tone2 -- its hue, its
    // chroma and its lightness -- while the negative side is left exactly as it
    // was. That is what "replaces the spread-derived neighbour on that side"
    // means, and it is why spread still matters under duotone: spread is the
    // axis, and it is what widens the palette around EACH anchor.
    //
    // Decomposed into pos and neg rather than clamped to the cap, because opal
    // deliberately runs its spread a third past MH_SPREAD and a clamp here would
    // silently take that back.
    //
    // At duo = 0 the positive side's mix returns MH_SPREAD, the two halves
    // recombine to exactly `hue`, and both scales are exactly 1: the identity,
    // for any magnitude, with no epsilon anywhere in it.
    float a = hue * (1.0 / MH_SPREAD);
    float pos = max(a, 0.0), neg = max(-a, 0.0);
    float rot = -neg * MH_SPREAD + pos * mix(MH_SPREAD, p.dHue, p.duo);
    float w = min(pos, 1.0) * p.duo;
    float cS = 1.0 + w * (p.dC - 1.0);
    float lS = 1.0 + w * (p.dL - 1.0);

    float ch = cos(rot), sh = sin(rot);
    lab.yz = float2(lab.y * ch - lab.z * sh, lab.y * sh + lab.z * ch) * cS;
    lab.x *= lS;
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
    //
    // And it is switched off as the ground goes light, because on paper the top
    // of the rail is the DEEPEST colour rather than the brightest: multiplying
    // it up would walk the darkest part of the picture back toward the page and
    // undo the one mechanism the light rail has.
    return col * (1.0 + emis * G * (1.0 - pal.paper) * smoothstep(0.72, 1.0, tRail));
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

/// One lane of the hash, for the gesture clock. Copied.
static inline float mh_hash1(float cell, float lane) {
    return float(mh_hash(uint3(uint(int(cell) + 32768), uint(int(lane) + 32768), 0x9E3779B9u)) >> 8)
         * (1.0 / 16777216.0);
}

/// THE FLOURISH CLOCK, and it is the pack's play mechanism.
///
/// Every hero from the second batch on performs ONE gesture: a thing the
/// presence does now and then and then lets go of. Nebula buries a glint in the
/// mist; prism's shafts fan wide and pulse; duet's pair draws close and hurries
/// round each other; still's single glint crossing the glass IS its entire
/// species. The clock says when, and the three rules it exists to keep are all
/// in its arithmetic.
///
/// APERIODIC, NEVER A METRONOME. Time is cut into slots and each slot holds
/// exactly one gesture, but WHERE in its slot the gesture falls is hashed per
/// slot. The interval between two onsets is therefore the slot length plus the
/// difference of two independent jitters, so no two gaps are the same and there
/// is nothing for the eye to lock onto. The slot length is a parameter here
/// rather than the exemplar's constant, because these four want very different
/// tempos: still is briefed at one glint every ten seconds or so, and nebula's
/// buried glint wants to come round rather more often than that.
///
/// DETERMINISTIC. The slot index is floor(t / slot) and everything else is a
/// hash of it, so any t at all renders the correct frame: a screenshot rig, a
/// scrubbed slider and a resumed app all agree. There is no state between frames
/// anywhere in this pack and play does not get to be the exception.
///
/// NOTHING SNAPS. The envelope is sin^2(pi u), which is zero with zero slope at
/// both ends. It does not begin, it arrives; it does not stop, it finishes.
///
/// Returns (envelope, progress, a per-gesture random, the gesture's duration).
/// The random is what each hero spends on WHERE the gesture happens, so no two
/// occurrences are in the same place, and it is stable for the whole gesture
/// because it is hashed from the slot rather than from the time.
static float4 mh_flourish(float t, float lane, float slotLen) {
    float SLOT = max(slotLen, 1.0);
    float slot = floor(t / SLOT);
    float local = t - slot * SLOT;
    float start = 0.9 + (SLOT * 0.28) * mh_hash1(slot, lane);
    float dur   = SLOT * (0.24 + 0.16 * mh_hash1(slot + 811.0, lane));
    float u = (local - start) / dur;
    float sn = sin(3.14159265 * clamp(u, 0.0, 1.0));
    float env = (u <= 0.0 || u >= 1.0) ? 0.0 : sn * sn;
    return float4(env, clamp(u, 0.0, 1.0), mh_hash1(slot + 1607.0, lane), dur);
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

/// HOW FAR THE INTERIOR SWIMS WHEN THE DEVICE TURNS.
///
/// 0.13 of a radian-ish lean per unit of tilt, which over a two-unit chord
/// moves the far side of the interior about a quarter of the body's radius
/// while the near side barely stirs. That difference IS the parallax and it is
/// the whole point: a picture that slid rigidly with the phone would read as a
/// texture being panned, where content at different depths moving at different
/// rates is the one cue the eye accepts as "there is really something in there".
///
/// Deliberately small. The reference for this is a spirit level or a compass
/// under glass, not a marble in a bowl; at twice this it stops being a material
/// property and becomes a toy.
constant float MH_TILT = 0.13;

/// THE INTERIOR'S LOOK DIRECTION, and the single place tilt enters the family.
///
/// Bending the RAY rather than moving the content is what makes one line serve
/// all eighteen heroes: every interior in this file is expressed against this
/// direction, whether it is marched (aura's sheets, nebula's weather) or solved
/// in closed form (droplet's heart, comet's head, duet's pair, arc's filament,
/// fathom's shells), so all of them parallax correctly and none of them needed a
/// word changed. And because the offset accumulates along the ray, deep content
/// moves further than shallow content for free -- which is the behaviour the
/// brief asks for and would have been fiddly to arrange any other way.
///
/// The body, the rim and the silhouette are built from the surface normal and
/// the entry point, neither of which this touches, so the glass itself holds
/// perfectly still while its contents swim. That contrast is what sells it.
///
/// The zero test is exact rather than an epsilon: at tilt (0,0) this returns
/// mh_refract's own vector untouched, so there is not even a renormalise
/// between today's render and today's render.
static inline float3 mh_look(float3 V, float3 N, float2 tilt) {
    float3 rd = mh_refract(V, N, MH_ETA);
    if (tilt.x == 0.0 && tilt.y == 0.0) return rd;
    return normalize(rd + float3(tilt.x, tilt.y, 0.0) * MH_TILT);
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

/// THE KEY, and it is a shared function rather than a local because one hero
/// needs to know where it is. The light sits up and to the left and drifts about
/// four degrees over half a minute, which is enough that the highlight is never
/// in the same place twice and not enough that anybody watches it move. Screen y
/// runs DOWN in a colorEffect, so up-left is negative in both.
///
/// It is further out than a beauty light would be: at (-0.52, -0.60) the
/// highlight lands at about 0.45 of the radius, clear of whatever the hero has
/// put in the middle. Pulled in toward the axis it sat directly on top of
/// droplet's heart and comet's orbit and stopped being a separate event.
///
/// mh_prism reads this to place the entry point of the light it splits, so its
/// shafts enter the glass at the same spot the specular says the light is coming
/// from. Two independent copies of the same direction would drift apart the
/// first time either was tuned, and a prism whose beams enter somewhere other
/// than its own highlight is a prism nobody believes.
static inline float3 mh_key(float t) {
    float dr = t * 0.21;
    return normalize(float3(-0.52 + 0.055 * sin(dr),
                            -0.60 + 0.045 * cos(dr * 0.83),
                             0.61));
}
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
static MHSurface mh_surface(MHBody b, float t, float small, half4 inkColor,
                            float2 tilt, float rimK, float specK, float glowK) {
    MHSurface o;
    float paper = mh_paper(inkColor);
    // The edge does more work on paper than it ever does on ink: it is the whole
    // silhouette of an object that is otherwise nearly the colour of the page,
    // and at small mounts it is very close to the only thing there is. A third
    // more of it, and no other term changes.
    rimK *= mix(1.0, 1.32, paper);

    // THE BARELY COUNTER-MOVE. Tilting the phone turns the ORB relative to the
    // room, so the room's light arrives from a slightly different angle and the
    // catchlight shifts -- against the tilt, because the world stays put while
    // the object turns. It is a fifth of what the interior does and it is meant
    // to be subliminal: what the eye should notice is the contents swimming
    // while the glass holds, and a highlight that moved as much as the interior
    // would say the whole object was sliding instead.
    float3 H = normalize(mh_key(t) - float3(tilt.x, tilt.y, 0.0) * (MH_TILT * 0.20)
                         + float3(0.0, 0.0, 1.0));
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
    o.spec = (pow(nh, tight) + 0.09 * pow(nh, 4.0)) * b.m * specK
           * mix(0.92, 1.08, 0.5 - 0.5 * clamp(b.N.y, -1.0, 1.0));

    // The wrap is a LIGHTING cue -- brighter on the side away from the key --
    // and on paper the rim is not lighting at all: it is the refracted edge of a
    // clear sphere, which is a property of the geometry and goes all the way
    // round. So the asymmetry flattens as the ground goes light. Left in, the
    // dark edge faded out along its top and the sphere read as a crescent with a
    // shadow rather than as a closed object on a page.
    float wrap = 0.55 + 0.45 * clamp(dot(normalize(b.N.xy + float2(1e-4)),
                                         normalize(float2(0.42, 0.50))), 0.0, 1.0);
    wrap = mix(wrap, 0.88, paper);
    // Exponent 3.9, and it was fitted against a capture rather than chosen: at 3
    // the rim is a broad wash that reads as the body being lit from behind, and
    // the shell's boundary disappears into it. At 3.9 the light lives in the
    // outer eighth and the eye gets a CRISP EDGE with soft content behind it,
    // which is the single strongest cue that there is a shell at all.
    //
    // It tightens to 5.4 on paper, where the rim is no longer a glow but the
    // dark refracted edge of a clear sphere -- and a dark edge has to be FINE to
    // read as an edge rather than as a dirty ring. Same term, opposite polarity,
    // because the rail underneath it has turned over.
    // THE ENVIRONMENT, and the rule for it is that if you can see it, it is
    // wrong. A real glass body reflects a room: brighter off whatever is above
    // it, darker off whatever is below. So the rim and the catchlight carry a
    // soft vertical gradient read straight off the surface normal -- fourteen
    // per cent on the rim, eight on the specular -- and that is the entire
    // feature. It is not a light and it does not move; it is the reason the
    // glass looks like it is somewhere.
    //
    // IT IS A VALUE GRADIENT AND NOT A COLOUR ONE, on purpose. A cool sky and a
    // warm ground is what an environment really does and it is exactly what this
    // family may not have: a second hue in the picture, arriving through a term
    // nobody dialled, would break the one-hue-family law from underneath.
    //
    // AND IT INVERTS ON PAPER. There, rim energy walks a descending rail, so
    // more of it is DARKER -- and a sky-lit top edge on a light ground has to be
    // paler, not deeper. Same gradient, mirrored, so the top of the sphere is
    // the lighter half of its edge on both grounds.
    //
    // Screen y runs down, so a normal pointing up has negative y.
    float sky = 0.5 - 0.5 * clamp(b.N.y, -1.0, 1.0);
    float envRim = mix(mix(0.86, 1.14, sky), mix(1.14, 0.86, sky), paper);

    o.rim = pow(b.fres, mix(3.9, 5.4, paper)) * b.m * wrap * rimK * envRim;

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

/// THE FINISH, and the one place the two grounds are told apart.
///
/// Ink underneath, the body composited into it by the containment, a knee, and
/// the dither last. Every hero ends on this line, which is most of why they read
/// as one material with twelve things happening inside it.
///
/// THE ARGUMENTS SPLIT because the light ground needs them to. On ink, the
/// interior, the rim, the specular and the contact bloom are all light and all
/// belong in one energy: sum them, walk the rail, done -- which is exactly what
/// happens below when `paper` is zero, bit for bit as the first eight heroes
/// were reviewed. On paper two of the four stop being light:
///
///   THE SPECULAR IS THE ONLY THING BRIGHTER THAN THE PAGE. Everything else in
///   the picture is the page minus something. So it leaves the energy sum -- if
///   it stayed, the descending rail would render the brightest thing in the
///   frame as the darkest -- and comes back as a small mix toward a warm white
///   pushed a little past 1, so it clips crisply against the pale body it sits
///   on. That body being pale is what makes it visible; a catchlight needs a
///   surround, not a brightness.
///
///   THE CONTACT BLOOM BECOMES A CONTACT SHADOW. Light spilling into ink is a
///   glow; the same term on paper is what an object occludes, so it turns into a
///   soft neutral darkening of the page and is weighted further downward, the
///   way a shadow pools under a thing rather than around it. `below` is read
///   from uv rather than from the body, because a shadow belongs to the ground
///   and not to the sphere.
///
/// THE KNEE MOVES with the ground too. At 0.90 it exists to stop a bright field
/// becoming flat white paper -- but when the ground already IS paper, sitting at
/// about 0.91 in linear light, that same knee spends all its headroom on the
/// page and leaves the catchlight nowhere to go. At 0.96 the page passes through
/// almost untouched and the highlight still compresses rather than clipping
/// hard.
///
/// `hue` is the spread offset the hero accumulated, already weighted by which
/// part of the picture is carrying colour: a pixel that is mostly specular gets
/// almost none of it, because a highlight is the colour of the light rather than
/// the colour of the thing it landed on.
static inline half4 mh_present(float body, float spec, float contact, float hue,
                               float2 uv, MHPalette pal, float glow,
                               half4 inkColor, float2 position, float pixelScale) {
    float paper = pal.paper;
    float dark = 1.0 - paper;

    // What walks the rail. On ink that is everything; on paper the specular and
    // the contact term have both left to be composited instead.
    float railE = body + (spec + contact) * dark;
    float3 field = mh_lit(pal, railE, glow, 0.0, 1.0, 0.34, hue);

    float3 inkLin = mh_srgb_to_linear(float3(inkColor.rgb));
    float3 rgb = mix(inkLin, field, mh_containment(uv, 0.72));

    if (paper > 0.002) {
        // THE CATCHLIGHT. A warm white a whisper past the page, so the knee
        // below turns it into a crisp small highlight rather than a soft one.
        float3 lit = mh_oklab_to_linear(mh_lch(min(pal.s0.x * 1.06 + 0.05, 1.02), 0.012, 0.9));
        // A SMOOTHSTEP RATHER THAN A CLAMP, so only the tight lobe's core takes
        // the white. On ink the specular's broad sheen is welcome light; on
        // paper the same sheen mixed toward white spread the catchlight into a
        // grey smudge half the width of the body, because a soft white on a
        // white page has no edge to be soft against. The threshold sits above
        // the broad lobe's ceiling, so what reaches the page is the glint alone.
        rgb = mix(rgb, lit, smoothstep(0.34, 0.92, spec) * paper);

        // THE CONTACT SHADOW, pooled beneath and neutral: an occlusion belongs
        // to the page, so it takes the page's own colour darkened rather than
        // the tone's.
        // A shadow POOLS, it does not ring. The first cut kept three tenths of
        // the term all the way round the body and the sphere came out sitting in
        // a soft grey halo, which is the one thing a contact shadow must never
        // look like. At 0.06 above the centre line and full below it, the page
        // is clean over the top of the object and darkens under it.
        float below = smoothstep(-0.10, 0.66, uv.y / MH_R);
        float3 shade = inkLin * 0.55;
        rgb = mix(rgb, shade, clamp(contact * 2.60, 0.0, 1.0) * (0.06 + 1.05 * below) * paper);
    }

    float knee = mix(0.90, 0.96, paper);
    rgb = float3(mh_knee(rgb.r, knee), mh_knee(rgb.g, knee), mh_knee(rgb.b, knee));
    return mh_out(rgb, position * pixelScale);
}


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
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
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
    float3 rd = mh_look(V, b.N, tilt);
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
    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.88 + 0.40 * live.voice, 0.52, 0.16);
    // The rim borrows the interior's colour, because it IS the interior seen
    // edge-on through more glass. The specular does not: it is the key light.
    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(e - sf.spec - sf.glow, sf.spec, sf.glow, hueMix,
                       uv, pal, glow, inkColor, position, pixelScale);
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
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
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
    float3 rd = mh_look(V, b.N, tilt);
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
    MHSurface sf = mh_surface(b, t, small, inkColor, tilt,
                              1.05 + 0.55 * sheenK + 0.35 * live.voice,
                              0.42 + 0.30 * sheenK,
                              0.16);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.6) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(e - sf.spec - sf.glow, sf.spec, sf.glow, hueMix,
                       uv, pal, glow, inkColor, position, pixelScale);
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
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
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
    float3 rd = mh_look(V, b.N, tilt);
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
    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.30, 0.78 + 0.35 * live.voice, 0.09);

    float e = interior + rimE + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (rimE + interior) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(e - sf.spec - sf.glow, sf.spec, sf.glow, hueMix,
                       uv, pal, glow, inkColor, position, pixelScale);
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
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
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
    float3 rd = mh_look(V, b.N, tilt);
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
    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.80 + 0.35 * live.voice, 0.22, 0.15);

    float e = interior + headE + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(e - sf.spec - sf.glow, sf.spec, sf.glow, hueMix,
                       uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 5. Nebula

// NEBULA. The volumetric showcase: there is no object in this glass at all.
//
// EVERY OTHER HERO PUTS SOMETHING INSIDE THE BODY and lets the medium carry it.
// This one deletes the something. The mist IS the species, and the whole design
// question is whether five samples down a refracted ray can make a cloud read as
// a cloud rather than as a soft gradient with noise on it. The answer turned out
// to be one structural decision plus one line of arithmetic.
//
// THE STRUCTURAL DECISION: THE MIST IS LIT FROM WITHIN, NOT UNIFORMLY. Emission
// rises toward the middle of the body and absorption does not, so what the eye
// gets is a deep glow with folds of denser material hanging in front of it. That
// is what makes a nebula a nebula -- the dark parts are dark because something
// is IN FRONT, not because nothing is there -- and a mist that emits evenly
// everywhere can never produce it however beautifully it folds.
//
// THE LINE OF ARITHMETIC is the transmittance: absorption is proportional to the
// same density that emits, at a coefficient high enough that a dense fold
// genuinely swallows what is behind it. Round-one heroes ran this low because
// their content was sparse. Here it is the whole point: NEARER FOLDS OCCLUDE
// FARTHER GLOW, and that sentence is a coefficient of 3.1.
//
// THE FOLDING is a domain warp: one noise displaces the coordinates the second
// noise is read at. Two samples per tap, which is the entire budget this species
// gets and the reason it can afford to be the only hero with real turbulence. A
// single octave read straight would be lumpy rather than folded, and an fBm deep
// enough to fold on its own would cost four times as much for a result the five
// taps would average away.
//
// ACTIVITY STIRS IT, which is the brief and also the honest mapping: cadence
// raises the WARP AMPLITUDE and the drift rate together, so a thinking assistant
// visibly churns its own weather rather than merely running the same clouds
// faster. LEVEL LIGHTS IT: voice lifts the deep glow and quickens the fold, so a
// room with somebody talking in it has a brighter, livelier interior.
//
// RESPONDING GIVES THE WEATHER A DIRECTION. A current switches on and the whole
// domain advects along one axis, so the mist stops churning in place and starts
// streaming. Turbulence with a heading is the only way this species can say
// "answering now" without abandoning its own physics.
//
// THE GESTURE, and it is buried on purpose: every seven seconds or so a glint
// lights somewhere inside the cloud and drifts a little way before fading. It is
// evaluated INSIDE the march rather than solved at closest approach, which is
// the opposite of what comet and droplet do and is deliberate -- a glint that is
// occluded by the mist in front of it is a glint that is inside the weather, and
// solving it outside the loop would paste it on top. Wide enough (0.13) that
// five taps resolve it without aliasing, which is what buys that.
//
// SIZE: at 18 pt the noise scale drops by nearly half so the features are large
// enough to be features rather than grain, the warp comes down with it because a
// folded cloud four pixels across is just noise, and the glint grows by two
// thirds and brightens. What survives is one slow billow of warm light with a
// dark fold across it, which is the species stated in the fewest marks it has.
[[ stitchable ]] half4 mh_nebula(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float densityK = clamp(c0, 0.0, 1.0);   // how thick the weather is
    float foldK    = clamp(c1, 0.0, 1.0);   // how hard it folds
    float glintK   = clamp(c2, 0.0, 1.0);   // the buried gesture
    float spreadK  = clamp(c3, 0.0, 1.0);   // hue across depth

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.022 + 0.008 * mh_breath(t, 1.6), 0.0, 1.25);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    // The mist's scale. Larger features at small mounts, because a fold has to be
    // several pixels across before it is a fold.
    float scale = (2.20 / S) * mix(1.0, 0.58, small);
    float warpScale = (1.30 / S) * mix(1.0, 0.60, small);
    float fold = (0.30 + 0.70 * foldK) * (1.0 + 0.75 * live.pace) * mix(1.0, 0.55, small);

    // The weather's own clock, eased, quickened by cadence and by voice.
    float dr = mh_drift(t, 0.052 + 0.055 * foldK, 0.45, 2.0)
             * (1.0 + 0.65 * live.pace + 0.35 * live.voice + 0.90 * st.drive);
    // RESPONDING: the whole domain streams one way.
    float3 adv = float3(0.86, 0.24, -0.45) * (st.drive * 0.42 * t);

    float absorb = 3.10 * (0.55 + 0.85 * densityK);
    float emit   = 0.62 + 0.85 * densityK;

    // THE BURIED GLINT. Position hashed per gesture from the flourish's own
    // random, so it lights somewhere new each time and stays put for the whole
    // gesture; it drifts a little way across its life.
    float4 fl = mh_flourish(t, 3.0, 7.2);
    float ga = fl.z * 6.2831853;
    float3 gp = 0.46 * float3(cos(ga), 0.72 * sin(ga * 1.7 + 1.1), sin(ga * 0.9 + 2.7))
              + float3(0.0, -0.16, 0.06) * fl.y;
    float gw = (0.130 + 0.045 * glintK) * S * mix(1.0, 1.65, small);
    float gAmp = fl.x * (0.55 + 1.35 * glintK) * mix(1.0, 1.55, small);

    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        // THE FOLD. One noise displaces the coordinates the next is read at.
        float w = mh_noise3(p * warpScale + float3(0.0, dr * 0.70, dr) - adv * 0.5);
        float3 q = p * scale + w * fold * float3(0.92, -0.58, 0.71)
                 + float3(0.0, 0.0, dr) - adv;
        float n = mh_noise3(q);

        // Clear gaps and dense cores, rather than an even haze: the smoothstep's
        // lower edge is what puts real holes in the cloud, and holes are what
        // make the folds in front of them read as objects.
        float dens = smoothstep(-0.20, 0.30, n) * fade;

        // LIT FROM WITHIN. Emission rises toward the middle; absorption does not.
        float glowIn = 0.30 + 0.95 * (1.0 - smoothstep(0.0, 0.88, length(p)));
        float e = dens * glowIn * emit * (1.0 + 0.75 * live.voice);

        // SUCCESS: the cloud ignites from the inside and a front travels out
        // through it, brightening what is already there.
        if (st.complete > 0.001) {
            float sr = (length(p) - mix(0.02, 1.05, st.sweep)) / 0.24;
            e *= 1.0 + 0.65 * st.complete;
            e += st.complete * 0.50 * exp(-sr * sr) * dens;
        }

        // The gesture, inside the weather so the weather can hide it.
        if (gAmp > 0.002) {
            float3 dg = (p - gp) / max(gw, 1e-3);
            float garg = dot(dg, dg);
            e += gAmp * (exp(-garg) * 0.75 + mh_scatter(garg, 0.22));
        }

        acc.x += e * trans * ds;
        // Depth carries the spread: the near folds one way, the deep glow the
        // other, so the cloud has two hues in conversation through its thickness.
        acc.y += e * clamp(p.z, -1.0, 1.0) * trans * ds;
        // THE LINE. Density absorbs at 3.1, which is what makes a near fold a
        // silhouette against the glow behind it rather than an addition to it.
        trans *= exp(-(absorb * dens + MH_EXT) * ds);
    }

    float interior = acc.x * 3.30 * b.m * mh_transmit(b.fres) * (1.0 + 0.20 * st.settled);
    float hue = (acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD;

    // The catchlight has to punch through weather. At 0.60 the cloud's own body
    // sat close enough to it that the frame had no cream in it anywhere and the
    // value hierarchy failed: a nebula is still an object with a lit surface.
    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.78 + 0.35 * live.voice, 0.98, 0.15);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(e - sf.spec - sf.glow, sf.spec, sf.glow, hueMix,
                       uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 6. Prism

// PRISM. Light entering the glass and softly splitting inside it.
//
// THE ENTRY POINT IS NOT ARBITRARY, and this is the species' one non-negotiable.
// The shafts begin where the specular highlight is, because that is where the
// picture already says the light is coming from, and a prism whose beams enter
// somewhere else is a prism nobody believes for a second. mh_key is a shared
// function for exactly this reason: the highlight and the entry point read the
// same direction, including its slow drift, and they cannot come apart when
// either is tuned.
//
// SHAFTS, NEVER RAYS. Each beam is a soft cone rather than a line: a gaussian in
// the perpendicular distance to its axis, whose width GROWS with distance from
// the entry, plus the kit's scatter on the same argument. A beam of constant
// width is a laser and a laser is the failure mode named in the brief; a beam
// that opens as it travels is a shaft of light in a medium, which is what this
// is. The fade-in over the first fifth of the path is what keeps the entry from
// being a hard bright dot, and the fade-out before the far wall is what keeps
// the shafts from painting themselves onto the inside of the shell.
//
// THE SPLIT IS A FAN in one plane, which is what a prism does: three directions
// spread symmetrically about the axis, and `split` is the half-angle. The middle
// beam sits on the anchor hue and the outer two are rotated to either side, so
// SPREAD DOES REAL WORK HERE -- at spread 0.6 this species shows three
// neighbouring hues separated in space rather than mixed, which is the most
// literal use of the knob anywhere in the collection and the reason its default
// is the highest of the twelve.
//
// LEVEL OPENS THE APERTURE: voice brightens the shafts and widens them, so more
// light is entering the glass when somebody is speaking. ACTIVITY RUNS DOWN
// THEM: cadence puts a travelling brightness along the shafts' length, gated by
// mh_aa so it switches itself off at the sizes where it would only be moire.
//
// RESPONDING CONVERGES THEM. The fan closes toward a single strong shaft driving
// through the body, brighter and straighter than the three were. A split that
// gathers itself into one beam is this species' way of saying "answering now",
// and it is the exact inverse of the gesture below, which is the point.
//
// THE GESTURE: every nine seconds or so the fan opens wider than it ever
// otherwise does and a bright pulse runs down the shafts to the far side. Light
// being worked on.
//
// SUCCESS: the pulse runs down every beam at once on the state's sweep and the
// whole bundle lifts, then settles brighter. The ignition travels, per the law.
//
// SIZE: at 18 pt the third beam crossfades away and the remaining two are nearly
// twice as wide -- a 0.05 body-unit shaft is under a pixel down there and would
// alias into a dotted line -- the travelling shimmer is gone, and the fan opens
// wider so the two are unmistakably two. What survives is a wide soft wedge of
// light entering a warm bead, which is the species in one gesture.
[[ stitchable ]] half4 mh_prism(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float beamsK  = clamp(c0, 0.0, 1.0);   // how wide the shafts are
    float splitK  = clamp(c1, 0.0, 1.0);   // the fan's half-angle
    float driftK  = clamp(c2, 0.0, 1.0);   // how much the bundle swings
    float spreadK = clamp(c3, 0.0, 1.0);   // the hues the split separates

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.021 + 0.007 * mh_breath(t, 2.4), 0.0, 1.20);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float4 fl = mh_flourish(t, 8.0, 9.1);

    // WHERE THE LIGHT ENTERS: the shared key, on the shell, swinging slowly.
    float sw = mh_drift(t, 0.048 + 0.040 * driftK, 0.52, 4.0);
    float3 key = mh_key(t);
    float3 O = normalize(key + (0.06 + 0.10 * driftK) * float3(sin(sw), cos(sw * 0.83), sin(sw * 0.61))) * 1.03;

    // WHERE THE BUNDLE IS AIMED, and this is the difference between shafts and
    // tadpoles. Pointing it at the centre -- the obvious choice, straight in from
    // the entry -- sends the beams substantially AWAY from the viewer, because
    // the entry is on the front of the sphere. Their length then foreshortens to
    // barely more than their width and three shafts render as three blobs, which
    // is what the first cut drew. Aiming instead at a point low and slightly
    // toward the viewer sends them across the body from upper left to lower
    // right, almost in the screen plane, so nearly their whole length is visible
    // and each one reads as a shaft with a direction. The light still enters
    // where the highlight says it does; it just refracts on the way in, which is
    // both what glass does and what this species needed.
    float3 axis = normalize(float3(0.10, 0.62, 0.28) - O);
    // THE FAN MUST OPEN ACROSS THE SCREEN, NOT INTO IT, and this is the frame
    // that guarantees it. The first cut picked an arbitrary reference vector,
    // which put the split plane at whatever angle happened to fall out -- and
    // since the beams already travel substantially away from the viewer, that
    // angle was mostly DEPTH: three beams genuinely diverging, all three landing
    // on top of each other in the image, drawing one wedge. Taking u1 as the
    // cross of the axis with the view direction puts it in the screen plane by
    // construction, so the fan is always seen side-on and the split is always
    // visible. u2 is then what is left, which is the depth direction, and it is
    // used only for the small wobbles that keep the beams from being coplanar.
    float3 u1 = normalize(cross(axis, float3(0.0, 0.0, 1.0)) + float3(1e-4, 0.0, 0.0));
    float3 u2 = normalize(cross(axis, u1));

    // THE FAN. Responding closes it; the gesture opens it wider than it ever
    // otherwise goes.
    float div = (0.17 + 0.42 * splitK) * mix(1.0, 1.35, small)
              * (1.0 - 0.62 * st.drive) * (1.0 + 0.55 * fl.x);
    float3 d0 = normalize(axis - u1 * div + u2 * (0.05 * sin(t * 0.071)));
    float3 d1 = normalize(axis + u2 * (0.06 * sin(t * 0.043 + 1.1)));
    float3 d2 = normalize(axis + u1 * div - u2 * (0.05 * sin(t * 0.059 + 2.2)));

    // Widths. The shaft opens as it travels: that spread is what makes it a
    // shaft rather than a rod.
    // THE OPENING RATE IS THE WHOLE SPECIES' BUDGET. The first cut let each
    // shaft grow by 0.155 body units per unit travelled, which over a path of
    // two is a beam nearly four tenths wide at the far wall -- three of those
    // plus their scatter is not a split, it is one lit balloon, which is exactly
    // what it drew. At 0.055 a shaft roughly triples in width crossing the body:
    // unmistakably opening, and still three separable things when it arrives.
    float w0 = (0.038 + 0.035 * beamsK) * S * mix(1.0, 1.85, small) * (1.0 + 0.30 * live.voice);
    float wGrow = 0.040 + 0.035 * beamsK;

    float third = 1.0 - smoothstep(0.30, 0.72, small);
    float bright = (0.76 + 0.65 * live.voice) * (1.0 + 0.55 * st.drive);

    // The travelling brightness cadence puts down the shafts, and the gate that
    // retires it when a cycle would be under two pixels.
    float shimGate = mh_aa(6.2831853 * 5.4 / (MH_R * S), size, pixelScale) * (1.0 - small);
    float shimAmt = shimGate * 0.55 * live.pace;

    float medAmt = mix(0.058, 0.030, small);

    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        float3 v = p - O;
        float vv = dot(v, v);

        // Beam 0.
        float s0 = dot(v, d0);
        float ww0 = w0 + wGrow * max(s0, 0.0);
        float a0 = max(vv - s0 * s0, 0.0) / (ww0 * ww0);
        float al0 = smoothstep(0.12, 0.46, s0) * (1.0 - smoothstep(1.60, 2.35, s0));
        float e0 = (exp(-a0) + mh_scatter(a0, 0.16)) * al0;

        // Beam 1, the middle of the fan and the one on the anchor hue.
        float s1 = dot(v, d1);
        float ww1 = w0 * 1.10 + wGrow * max(s1, 0.0);
        float a1 = max(vv - s1 * s1, 0.0) / (ww1 * ww1);
        float al1 = smoothstep(0.12, 0.46, s1) * (1.0 - smoothstep(1.60, 2.35, s1));
        float e1 = (exp(-a1) + mh_scatter(a1, 0.16)) * al1;

        // Beam 2, the one small mounts give up.
        float e2 = 0.0, s2 = 0.0;
        if (third > 0.002) {
            s2 = dot(v, d2);
            float ww2 = w0 + wGrow * max(s2, 0.0);
            float a2 = max(vv - s2 * s2, 0.0) / (ww2 * ww2);
            float al2 = smoothstep(0.12, 0.46, s2) * (1.0 - smoothstep(1.60, 2.35, s2));
            e2 = (exp(-a2) + mh_scatter(a2, 0.16)) * al2 * third;
        }

        // Cadence runs light down the shafts; the gesture and success send one
        // decisive pulse down all of them together.
        float run = 1.0;
        if (shimAmt > 0.002) {
            run += shimAmt * sin(s1 * 5.4 - t * 2.6);
        }
        float pulse = 0.0;
        if (fl.x > 0.002) {
            float pr = (s1 - fl.y * 2.0) / 0.28;
            pulse += fl.x * 1.05 * exp(-pr * pr);
        }
        if (st.complete > 0.001) {
            float pr = (s1 - st.sweep * 2.1) / 0.26;
            pulse += st.complete * 1.60 * exp(-pr * pr);
        }

        float beams = (e0 + e1 + e2) * bright * run * (1.0 + pulse)
                    * (1.0 + 1.10 * st.complete);

        // The split IS the hue: the outer beams sit either side of the anchor
        // and the middle one on it, weighted by which beam this pixel is in.
        float hueW = (e0 * -1.0 + e2 * 1.0) * bright * run;

        float med = mh_medium(p, t, 2.2 / S) * medAmt;
        float e = (beams * 0.95 + med) * fade;

        acc.x += e * trans * ds;
        acc.y += hueW * 0.95 * fade * trans * ds;
        trans *= exp(-(2.60 * e + MH_EXT) * ds);
    }

    float interior = acc.x * 2.45 * b.m * mh_transmit(b.fres) * (1.0 + 0.22 * st.settled);
    float hue = (acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD;

    // The catchlight marks where the light is entering, which is this species'
    // premise -- but it had to come down from 0.95. All three shafts converge at
    // the entry, so the brightest knot in the frame is there anyway; a hot
    // specular on top of it made one blob with legs, and the legs are the
    // species. At 0.62 the entry still reads unmistakably as the source and the
    // fan below it is what the eye follows.
    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.80 + 0.35 * live.voice,
                              0.62 + 0.25 * live.voice, 0.15);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.6) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(e - sf.spec - sf.glow, sf.spec, sf.glow, hueMix,
                       uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 7. Duet

// DUET. Two lights orbiting a common centre inside the glass: the conversation.
//
// TWO THINGS IN ONE VOLUME IS A DEPTH PROBLEM, and solving it properly is the
// whole species. Two bright blobs going round each other on a flat disc is a
// loading spinner; two bodies passing in front of and behind one another with
// the far one visibly dimmer and partly eaten by the near one is a conversation
// happening in a space. Three separate mechanisms produce that and each is one
// line:
//
//   THE ORBIT IS TILTED and precesses, so the pair's plane is never edge-on for
//   long and never face-on at all. Face-on is the spinner; edge-on is a line.
//   THE FAR ONE IS DIMMER. Both bodies are solved at the view ray's closest
//   approach, so each knows how deep into the glass it is, and exp(-MH_EXT * s)
//   does the rest -- the one at the back is seen through more material and comes
//   out at a third of the light.
//   THE NEAR ONE OCCLUDES THE FAR ONE. Whichever body the ray reaches first
//   attenuates the other by its own density at this pixel. That is the cue that
//   turns "dimmer" into "behind", and without it the pair reads as two lamps at
//   different brightnesses rather than as two objects at two depths.
//
// SOLVED, NOT SAMPLED, for the same reason droplet's heart is: bodies this
// compact marched at five steps come out as the shape of the sampling. Two dot
// products each, exact at every distance, and perfectly round from any angle.
//
// SPREAD IS THE TWO VOICES. One body sits a little warm of the anchor and the
// other a little cool of it, which is why this species carries the collection's
// joint-highest default: the difference between the two lights IS the content,
// and at spread 0 it degrades to two identical lamps, which is a duet with both
// parts written in unison.
//
// LEVEL SHIFTS THE BALANCE, and this is the reading of `level` the species
// exists for. At rest the glow sways slowly between the two -- turn and turn
// about, the conversation ticking over. As voice comes up it pushes decisively
// toward one of them: somebody has the floor. Not both brighter, which would say
// nothing; brighter THERE and dimmer here, which says who is speaking.
//
// ACTIVITY TIGHTENS AND QUICKENS the orbit a little, the way a busy exchange
// closes the distance between two people.
//
// RESPONDING BRAIDS THEM. The separation collapses by a third, the rate nearly
// doubles, and a weave switches on: each body is displaced along the orbit's own
// normal by a term running at three times the orbital rate and in opposite
// signs, so they wind around each other rather than merely circling faster. A
// braid is two things becoming one line without merging, which is exactly what a
// conversation in full flow looks like.
//
// THE GESTURE: every eight seconds or so the pair draws close and hurries once
// around each other before easing back out. Play, in this species' own grammar.
//
// SUCCESS: they rush together, the interior ignites as they meet, and they ease
// apart again brighter. The pattern is two things circling; completing it is
// their arrival at the same place.
//
// SIZE: at 18 pt the orbit opens from 0.41 to 0.56 of the body (a tight orbit in
// a small bead is a wobble, not two objects), both bodies grow by half, and the
// size ratio is pushed toward one so the smaller companion cannot vanish. What
// survives is two clean sparks turning around each other, which is the least the
// species can be and still be itself.
[[ stitchable ]] half4 mh_duet(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float sepK    = clamp(c0, 0.0, 1.0);   // how far apart they hold
    float orbitK  = clamp(c1, 0.0, 1.0);   // how fast they go round
    float ratioK  = clamp(c2, 0.0, 1.0);   // how alike in size they are
    float spreadK = clamp(c3, 0.0, 1.0);   // the two voices

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.023 + 0.007 * mh_breath(t, 3.1), 0.0, 1.25);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float4 fl = mh_flourish(t, 6.0, 8.3);

    // THE PLANE. Tilt bounded away from face-on and edge-on, wobbling slowly, and
    // precessing so the pair's geometry never repeats.
    float lean = 0.62 + 0.20 * sin(t * 0.037);
    float prec = mh_drift(t, 0.064, 0.45, 2.0);
    float3 e1 = mh_spin(float3(1.0, 0.0, 0.0), prec, 0.0);
    float3 e2 = mh_spin(float3(0.0, sin(lean), cos(lean)), prec, 0.0);
    float3 nrm = cross(e1, e2);

    // Separation. Cadence closes it a little, responding a lot, the gesture
    // briefly, and success all the way in.
    float r = mix(0.30, 0.50, sepK) * mix(1.0, 1.36, small) * S
            * (1.0 - 0.14 * live.pace) * (1.0 - 0.34 * st.drive)
            * (1.0 - 0.30 * fl.x) * (1.0 - 0.62 * st.complete);

    float rate = (0.40 + 0.55 * orbitK)
               * (1.0 + 0.55 * live.pace + 0.90 * st.drive + 0.85 * fl.x);
    float psi = mh_drift(t, rate, 0.40, 3.0);

    // THE BRAID: a weave along the orbit's normal, opposite in sign for the two,
    // running at three times the orbital rate. Off at rest, on under drive.
    float braid = (0.16 * st.drive + 0.06 * fl.x) * S * sin(psi * 3.0);

    float3 spoke = cos(psi) * e1 + sin(psi) * e2;
    float3 A =  r * spoke + nrm * braid;
    float3 B = -r * spoke - nrm * braid;

    // Sizes. The ratio closes toward one at small mounts so the companion cannot
    // disappear into a pixel.
    float wA = (0.145 + 0.030 * sepK) * S * mix(1.0, 1.50, small);
    float wB = wA * mix(0.52, 1.0, mix(ratioK, 1.0, small * 0.65));

    // THE BALANCE. A slow sway at rest, pushed decisively by voice.
    float sway = 0.5 + 0.15 * sin(mh_drift(t, 0.21, 0.50, 7.0));
    float bal = clamp(sway + 0.40 * live.voice, 0.06, 0.94);
    float brA = 2.0 * bal;
    float brB = 2.0 * (1.0 - bal);

    // Both bodies, at the ray's closest approach.
    float3 toA = A - b.P;
    float sA = dot(toA, rd);
    float argA = max(dot(toA, toA) - sA * sA, 0.0) / max(wA * wA, 1e-6);
    float visA = (sA > 0.0 && sA < L) ? mh_inside(b.P + rd * sA) * exp(-MH_EXT * sA) : 0.0;
    float coreA = exp(-argA) * visA;

    float3 toB = B - b.P;
    float sB = dot(toB, rd);
    float argB = max(dot(toB, toB) - sB * sB, 0.0) / max(wB * wB, 1e-6);
    float visB = (sB > 0.0 && sB < L) ? mh_inside(b.P + rd * sB) * exp(-MH_EXT * sB) : 0.0;
    float coreB = exp(-argB) * visB;

    // THE OCCLUSION, and it is the line that turns "dimmer" into "behind".
    // Whichever the ray reaches first eats the other by its own density here.
    float occA = 1.0, occB = 1.0;
    if (sA < sB) { occB = exp(-2.40 * coreA); } else { occA = exp(-2.40 * coreB); }

    float flare = 1.0 + 1.15 * st.complete;
    float eA = (coreA * 1.05 + mh_scatter(argA, 0.30) * visA) * brA * occA * flare;
    float eB = (coreB * 1.05 + mh_scatter(argB, 0.30) * visB) * brB * occB * flare;

    // The medium, and the ignition that travels out through it on success.
    float medAmt = mix(0.085, 0.044, small);
    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        float med = mh_medium(p, t, 2.2 / S) * medAmt;
        float e = med;
        if (st.complete > 0.001) {
            float sr = (length(p) - mix(0.02, 1.0, st.sweep)) / 0.22;
            e += st.complete * 0.26 * exp(-sr * sr);
        }
        acc.x += e * trans * ds;
        trans *= exp(-(2.20 * e + MH_EXT) * ds);
    }

    float interior = (acc.x * 3.60 + eA + eB) * b.m * mh_transmit(b.fres)
                   * (1.0 + 0.20 * st.settled);

    // THE TWO VOICES: A warm of the anchor, B cool of it, weighted by which body
    // this pixel is actually seeing.
    float hueW = (eA * 0.85 - eB * 1.0);
    float hue = (interior > 1e-4 ? hueW / max(eA + eB, 1e-4) : 0.0) * spreadK * MH_SPREAD;

    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.80 + 0.35 * live.voice, 0.42, 0.15);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (eA + eB) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(e - sf.spec - sf.glow, sf.spec, sf.glow, hueMix,
                       uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 8. Still

// STILL. The discipline piece: a quiet glass sphere and one slow glint.
//
// THE WHOLE BRIEF IS ONE SENTENCE -- intentional minimalism, never unfinished --
// and the distance between those two things is not a matter of adding or
// removing content. It is entirely the QUALITY OF THE RIM and the COMPOSURE OF
// THE GLINT. A nearly empty sphere with a mediocre edge reads as a hero that did
// not get finished; the same emptiness behind a beautifully turned rim reads as
// restraint. So this species spends almost its whole energy budget on the two
// things the kit does best and adds nearly nothing of its own.
//
// THE RIM AND SPECULAR RUN THE HIGHEST IN THE COLLECTION, and they are the
// figure rather than the finish: the specular is the brightest pixel in the
// frame by a wide margin and the rim carries the silhouette on its own. Every
// other hero has to keep those two in check so its interior can be seen. This
// one has no interior to protect, which is exactly the licence it needs.
//
// THE GLINT IS ONE THING, AND IT ARRIVES ON ITS OWN SCHEDULE. Every ten seconds
// or so -- the flourish clock's slot at the default `glintRate`, jittered so no
// two gaps match -- a small soft light crosses the volume, entering on one side
// and leaving by the other, brightening and fading on a curve with flat ends so
// it never begins and never stops. It is solved at the view ray's closest
// approach, which on this species matters more than on any other: it is the only
// event in the frame, so any flicker or smear in it is the whole picture
// failing. Composure means it is perfectly round, moves at an eased rate, and is
// gone before you have finished watching it.
//
// PRESENCE (c2) LIFTS A FAINT INTERIOR FLOOR, and it is the dial between the two
// readings. At zero the glass is optically empty and the species is at its most
// severe; at one there is a soft warmth in the body that makes the sphere read
// as full even between glints. CLARITY (c1) works against it: a clearer glass
// carries less of everything, so the two knobs together are the whole range from
// a dark bead with a bright edge to a warm one with a light asleep in it.
//
// LEVEL IS ATTENTION, NOT MOTION. Voice lifts the rim and the floor and
// brightens the glint, and that is deliberately all: a minimal presence that
// starts moving when somebody speaks is not minimal any more, it is just quiet
// until it is not. ACTIVITY QUICKENS THE GLINT'S CADENCE a little, so a busy
// assistant's one light comes round more often.
//
// RESPONDING is where the species drops its aperiodicity. The glints come nearly
// three times as fast and their paths converge on a single axis, so what was an
// occasional wander becomes a steady traverse across the body. Regular is
// exactly what idle must never be and exactly what answering should be.
//
// SUCCESS: a soft bloom rises from the middle and settles, and the glint that
// happens to be crossing brightens with it. The quietest arrival in the family,
// which is the right one for this hero.
//
// SIZE: at 18 pt the glint grows by four fifths and the floor lifts by half,
// because a nearly empty bead thirteen points across with nothing in it reads as
// a bug rather than as restraint. The specular's exponent falls from 96 to 16 in
// the kit, which spreads the same light over two or three pixels -- and on this
// species, where the highlight IS the figure, that is the single most important
// size adaptation in the file.
[[ stitchable ]] half4 mh_still(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float glintK    = clamp(c0, 0.0, 1.0);   // how often the one light comes
    float clarityK  = clamp(c1, 0.0, 1.0);   // how empty the glass is
    float presenceK = clamp(c2, 0.0, 1.0);   // the interior floor
    float spreadK   = clamp(c3, 0.0, 1.0);   // a whisper of hue through depth

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    // The quietest body in the collection: a whisper of deformation and the
    // lowest shading gain, because composure is the species and a lively normal
    // would be the first thing to break it.
    MHShape sh = mh_shape(0.018 + 0.006 * mh_breath(t, 4.2), 0.0, 1.12);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    // THE CLOCK. About eleven and a half seconds at glintRate 0, seven at 1, so
    // the default 0.3 lands near ten -- the brief's number -- with the flourish's
    // own jitter on top of it. Cadence and drive both hurry it.
    float slot = mix(11.5, 7.0, glintK) / (1.0 + 0.30 * live.pace + 1.70 * st.drive);
    float4 fl = mh_flourish(t, 5.0, slot);

    // THE PATH. It enters one side and leaves by the other, on a line hashed per
    // gesture. Under drive the lines converge on one axis, so an occasional
    // wander becomes a traverse.
    float ga = fl.z * 6.2831853;
    float3 dir = normalize(mix(float3(cos(ga), 0.42 * sin(ga * 1.3), sin(ga)),
                               float3(0.92, -0.18, 0.35), st.drive));
    float3 side = normalize(cross(dir, float3(0.06, 1.0, 0.12)));
    float3 gp = side * (0.34 * (fl.z * 2.0 - 1.0) * (1.0 - 0.7 * st.drive))
              + dir * mix(-0.62, 0.62, smoothstep(0.0, 1.0, fl.y));

    float gw = (0.085 + 0.055 * glintK) * S * mix(1.0, 1.80, small);
    float gBright = fl.x * (0.90 + 0.95 * live.voice) * (1.0 + 0.85 * st.complete);

    // THE GLINT, solved. On the only event in the frame, sampling artefacts are
    // the entire picture, so this one is never marched.
    float3 toG = gp - b.P;
    float sG = dot(toG, rd);
    float glint = 0.0;
    if (sG > 0.0 && sG < L) {
        float argG = max(dot(toG, toG) - sG * sG, 0.0) / max(gw * gw, 1e-6);
        float visG = mh_inside(b.P + rd * sG) * exp(-MH_EXT * sG);
        glint = (exp(-argG) * 1.05 + mh_scatter(argG, 0.38)) * visG * gBright;
    }

    // THE FLOOR. Presence lifts it, clarity takes it away, and voice adds a
    // little attention to it.
    float floorAmt = (0.016 + 0.085 * presenceK) * (1.0 - 0.50 * clarityK)
                   * (1.0 + 0.55 * live.voice) * mix(1.0, 1.50, small);

    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        float e = mh_medium(p, t, 1.9 / S) * floorAmt;
        // SUCCESS: a soft bloom out of the middle. The quietest arrival here.
        if (st.complete > 0.001) {
            float sr = (length(p) - mix(0.02, 0.95, st.sweep)) / 0.26;
            e += st.complete * 0.30 * exp(-sr * sr);
        }
        acc.x += e * trans * ds;
        acc.y += e * clamp(p.z, -1.0, 1.0) * trans * ds;
        trans *= exp(-(2.00 * e + MH_EXT) * ds);
    }

    float interior = (acc.x * 3.40 + glint) * b.m * mh_transmit(b.fres)
                   * (1.0 + 0.22 * st.settled);
    float hue = (acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD;

    // THE HIGHEST RIM AND SPECULAR IN THE COLLECTION, and the reason is in the
    // header: with no interior to protect, the edge and the highlight are free to
    // be the figure. This is the one hero whose brightest pixel is always its
    // catchlight, at every state and every size.
    MHSurface sf = mh_surface(b, t, small, inkColor, tilt,
                              1.15 + 0.45 * live.voice,
                              1.30 + 0.35 * live.voice,
                              0.13);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(e - sf.spec - sf.glow, sf.spec, sf.glow, hueMix,
                       uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 9. Fathom

// FATHOM. Layered translucent depths: nested shells, seen through each other.
//
// NOT MIST, AND THAT IS THE WHOLE DISTINCTION FROM NEBULA. Nebula's answer to
// depth is a cloud whose near folds silhouette against its own glow -- volume
// without any surface in it. This species goes the other way: three legible
// SURFACES at three radii, each one a thin translucent skin you can see the next
// one through. What the eye gets from a cloud is atmosphere; what it gets from
// nested shells is measurement, a sense of how far in the far one is, which is
// the species' name.
//
// THE SHELLS ARE SOLVED, NOT MARCHED, and that is what makes them legible. A
// shell is a thin surface, and five samples down a ray would catch it or miss it
// depending on where the tap planes happened to fall -- the same failure that
// cost comet its head and droplet its heart, except six times over. So each
// shell's crossings are found by intersecting the interior ray with a sphere,
// which is one quadratic: a ray that enters the body crosses every shell it
// reaches exactly twice, once going in and once coming out.
//
// AND THEY SORT THEMSELVES. Six crossings would normally have to be depth-sorted
// before they could be composited, which is not something a fragment shader
// wants to do. But the order is known in advance and cannot vary: a ray entering
// from outside meets the biggest shell first, then the middle, then the
// smallest, then the smallest again on the way out, then the middle, then the
// biggest. Outer-in, inner-out. So the accumulation is simply written in that
// sequence and the transmittance is correct with no sorting at all.
//
// GRAZING CROSSINGS GLOW, and this is the effect that sells translucency. The
// amount of material a ray meets crossing a thin shell is its thickness divided
// by the cosine of the angle between the ray and the surface, so a crossing near
// a shell's own limb passes through several times as much skin as one through
// its face. Each shell therefore wears a bright rim of its own, nested inside
// the last -- and it is free, because the cosine is a dot product the crossing
// already computed. The floor at 0.26 caps the amplification, because the exact
// grazing case divides by zero.
//
// THE FOLDS CATCH LIGHT. Each shell carries two low-order modes on its surface,
// rotating at its own rate, and they do two things at once: they displace the
// crossing along the ray by a first-order correction, so the shell is genuinely
// out of round and the near and far crossings disagree about where it is, and
// they modulate how much the skin catches the key. THE PARALLAX IS REAL because
// each shell turns at a different rate: watch any point of the front shell's
// fold and the pattern behind it slides the other way.
//
// LEVEL PUSHES THEM APART. Voice separates the radii, which opens up the space
// between the layers and makes the depth cue stronger, and deepens the folds.
// Not brighter -- deeper. ACTIVITY QUICKENS THE INDEPENDENT ROTATIONS, so the
// parallax between the layers animates faster: a thinking assistant's depths
// slide past each other.
//
// RESPONDING ALIGNS THE ROTATIONS and drives them one way, so three layers
// sliding independently become three layers travelling together.
//
// THE GESTURE, every nine seconds or so: the shells breathe apart and back.
//
// SUCCESS IGNITES THEM FROM THE INSIDE OUT, one layer at a time along the
// state's sweep -- the innermost first, then the middle, then the outer. An
// arrival that arrives THROUGH something is what this species has that the
// others do not.
//
// SIZE: at 18 pt the third shell crossfades away and the two that remain are
// nearly twice as thick and half as folded, because a fold four pixels across is
// a wobble rather than a fold. What survives is two nested translucent rings,
// which is the species stated in the fewest surfaces it can have and still be
// about depth.
[[ stitchable ]] half4 mh_fathom(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float layersK   = clamp(c0, 0.0, 1.0);   // how far apart the shells sit
    float parallaxK = clamp(c1, 0.0, 1.0);   // how fast they slide past each other
    float murkK     = clamp(c2, 0.0, 1.0);   // how absorbing the space between is
    float spreadK   = clamp(c3, 0.0, 1.0);   // hue across depth

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.021 + 0.007 * mh_breath(t, 5.3), 0.0, 1.20);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float4 fl = mh_flourish(t, 9.0, 9.4);
    float3 key = mh_key(t);

    // THE RADII. Voice and the gesture push them apart; the knob sets the span.
    float spanK = (1.0 + 0.22 * live.voice + 0.16 * fl.x);
    float R0 = (0.70 + 0.06 * layersK) * spanK * S;
    float R1 = (0.50 - 0.02 * layersK) * spanK * S;
    float R2 = (0.30 - 0.06 * layersK) * spanK * S;
    R0 = min(R0, 0.74);                          // never into mh_inside's fade

    float third = 1.0 - smoothstep(0.28, 0.68, small);
    float thick = (0.062 + 0.035 * layersK) * S * mix(1.0, 1.90, small);
    float foldAmp = (0.055 + 0.055 * parallaxK) * (1.0 + 0.55 * live.voice)
                  * mix(1.0, 0.50, small) * S;

    // Independent rotations, aligned by drive. Each shell's own rate is what the
    // parallax is made of; identical rates would be one shell drawn three times.
    float sp = (1.0 + 0.85 * live.pace + 1.10 * st.drive);
    float a0 = mh_drift(t, 0.085 * sp, 0.45, 1.0);
    float a1 = mix(mh_drift(t, -0.062 * sp, 0.50, 2.0), a0, st.drive * 0.7);
    float a2 = mix(mh_drift(t,  0.108 * sp, 0.40, 3.0), a0, st.drive * 0.7);

    float bq = dot(b.P, rd);
    float PP = dot(b.P, b.P);

    // Per-shell crossing data, filled below and then composited in the fixed
    // outer-in, inner-out order.
    float sN[3], sF[3], eN[3], eF[3];
    float3 dN[3], dF[3];
    for (int k = 0; k < 3; k++) { sN[k] = -1.0; sF[k] = -1.0; eN[k] = 0.0; eF[k] = 0.0;
                                  dN[k] = float3(0.0, 0.0, 1.0); dF[k] = float3(0.0, 0.0, 1.0); }

    // THE FOLD HAS TO MOVE THE OUTLINE. The first cut displaced each crossing
    // along the ray, which is geometrically honest and visually almost nothing:
    // a shell's apparent radius on screen is set by where its limb falls, and
    // the limb is decided by the radius used in the quadratic, not by anything
    // done to the crossing afterwards. Three shells came out as three perfect
    // concentric circles -- a target, not a set of folded surfaces.
    //
    // So the radius is folded per pixel, evaluated in the pixel's own IN-PLANE
    // direction, which is exactly the direction of the shell's limb there. Each
    // ring's outline now undulates organically, and every crossing behind it
    // moves with it. It is an approximation away from the limb and exact at it,
    // which is the right place for the error to be: the limb is where the
    // grazing glow puts the shell's brightest light and where its shape is read.
    float3 limbDir = normalize(float3(b.P.xy, 0.02) + 1e-5);
    float RK[3];
    {
        float3 axA = normalize(float3(cos(a0), 0.42, sin(a0)));
        float3 axB = normalize(float3(cos(a1), 0.42, sin(a1)));
        float3 axC = normalize(float3(cos(a2), 0.42, sin(a2)));
        // THE FOLD IS A FRACTION OF ITS OWN SHELL, not an absolute displacement.
        // At a fixed amplitude the same 0.08 that gently creases the outer shell
        // is a quarter of the inner one's radius, and the innermost came out as
        // a lopsided egg rather than as a small sphere with a crease in it.
        // Scaled by R over R0 they all fold by the same proportion, which is
        // what nested skins of one material would actually do.
        RK[0] = R0 + foldAmp * (R0 / max(R0, 1e-3))
                   * (0.62 * sin(2.30 * dot(limbDir, axA) + a0 * 1.7)
                    + 0.38 * sin(3.70 * dot(limbDir, axA.zxy) - a0 * 1.1 + 2.1));
        RK[1] = R1 + foldAmp * (R1 / max(R0, 1e-3))
                   * (0.62 * sin(2.30 * dot(limbDir, axB) + a1 * 1.7)
                    + 0.38 * sin(3.70 * dot(limbDir, axB.zxy) - a1 * 1.1 + 2.1));
        RK[2] = R2 + foldAmp * (R2 / max(R0, 1e-3))
                   * (0.62 * sin(2.30 * dot(limbDir, axC) + a2 * 1.7)
                    + 0.38 * sin(3.70 * dot(limbDir, axC.zxy) - a2 * 1.1 + 2.1));
    }
        float AK[3]; AK[0] = a0; AK[1] = a1; AK[2] = a2;
    // The outer shell is the one the light reaches first and the one whose fold
    // the brief asks to see catching it, so the three are not equally bright
    // intrinsically -- they fall away inward, and the transmittance then dims
    // them again on top of that. Equal weights made the innermost read as a
    // solid ball sitting inside two rings rather than as the deepest of three
    // skins.
    float WK[3]; WK[0] = 1.0; WK[1] = 0.74; WK[2] = 0.52 * third;

    for (int k = 0; k < 3; k++) {
        if (WK[k] < 0.002) continue;
        float R = RK[k];
        float disc = bq * bq - PP + R * R;
        if (disc <= 0.0) continue;
        float sq = sqrt(disc);
        float ss[2]; ss[0] = -bq - sq; ss[1] = -bq + sq;

        for (int h = 0; h < 2; h++) {
            float s = ss[h];
            if (s <= 0.0 || s >= L) continue;
            float3 pt = b.P + rd * s;
            float3 dir = normalize(pt + 1e-5);

            // The fold: two low-order modes on the shell's own turning axis.
            float3 ax = float3(cos(AK[k]), 0.42, sin(AK[k]));
            ax = normalize(ax);
            float f = 0.62 * sin(2.30 * dot(dir, ax) + AK[k] * 1.7)
                    + 0.38 * sin(3.70 * dot(dir, ax.zxy) - AK[k] * 1.1 + 2.1);

            float g = dot(dir, rd);

            // GRAZING GLOW. Thickness over the cosine: a crossing near this
            // shell's own limb passes through several times as much skin.
            float graze = thick / max(abs(g), 0.26);
            float lit = 0.40 + 0.60 * clamp(dot(dir, key), 0.0, 1.0);
            float e = graze * (0.42 + 0.58 * (0.5 + 0.5 * f)) * lit * WK[k];

            // SUCCESS travels outward one layer at a time: shell 2 lights first,
            // then 1, then 0, as the sweep passes each one's turn.
            if (st.complete > 0.001) {
                float turn = float(2 - k) * 0.33;
                float w = 1.0 - smoothstep(0.0, 0.42, abs(st.sweep - turn - 0.16));
                e *= 1.0 + st.complete * (0.5 + 2.4 * w);
            }

            if (h == 0) { sN[k] = s; eN[k] = e; dN[k] = dir; }
            else        { sF[k] = s; eF[k] = e; dF[k] = dir; }
        }
    }

    // The murk between the shells, marched: it is a medium, not a surface.
    float medAmt = (0.030 + 0.075 * murkK) * mix(1.0, 0.70, small);
    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);
    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;
        float e = mh_medium(p, t, 2.0 / S) * medAmt * fade;
        acc.x += e * trans * ds;
        trans *= exp(-(1.80 * e + MH_EXT) * ds);
    }
    float murkE = acc.x * 3.20;

    // THE SHELLS, front to back, in the order geometry guarantees.
    float shellE = 0.0, shellH = 0.0;
    float tr = 1.0;
    float absorb = 1.05 + 1.55 * murkK;
    int order[6]; order[0] = 0; order[1] = 1; order[2] = 2; order[3] = 2; order[4] = 1; order[5] = 0;
    for (int i = 0; i < 6; i++) {
        int k = order[i];
        bool nearHit = (i < 3);
        float s = nearHit ? sN[k] : sF[k];
        if (s < 0.0) continue;
        float e = (nearHit ? eN[k] : eF[k]) * exp(-MH_EXT * s);
        float3 dir = nearHit ? dN[k] : dF[k];
        shellE += e * tr;
        // Depth carries the hue: the near faces one way, the far the other, so
        // the layers are told apart by colour as well as by brightness.
        shellH += e * tr * clamp(dir.z, -1.0, 1.0);
        tr *= exp(-absorb * e);
    }

    float interior = (shellE * 4.30 + murkE) * b.m * mh_transmit(b.fres)
                   * (1.0 + 0.20 * st.settled);
    float hue = (shellE > 1e-4 ? shellH / shellE : 0.0) * spreadK * MH_SPREAD;

    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.78 + 0.35 * live.voice, 0.46, 0.14);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(interior + sf.rim, sf.spec, sf.glow, hueMix,
                      uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 10. Arc

// ARC. One soft bright filament arcing gently through the volume.
//
// THE SPECIES IS A LINE, and a line is the hardest thing this kit has been asked
// to draw. Everything else in the collection is either compact enough to solve
// at the ray's closest approach -- a point, a heart, a pair of bodies, a flash
// -- or broad enough that five samples average it honestly: ribbons, mist,
// curtains, shells. A filament is neither. It is thin enough that a march steps
// straight over it, and extended enough that there is no closed form for a
// ray's nearest approach to it.
//
// THE FIRST BUILD MARCHED IT AT TEN STEPS and the verdict on it was a fat slug
// of light, which was correct and which the march had made unavoidable. A
// sampled filament cannot be thinner than its sampling: at ten steps down a
// two-unit chord the interval is 0.2, so a tube narrower than that is caught by
// whichever tap happens to fall inside it and missed otherwise, and what draws
// is a line that is dim, uneven, and flickering as it moves. The only way to
// make ten taps honest was to widen the thread to 0.125 of the sphere's radius,
// which is a bolster. Sixteen taps would have bought 0.08 -- still not a thread
// -- at three times the cost.
//
// SO THE FILAMENT IS NOT MARCHED AT ALL. It is integrated in closed form, and
// the argument has three steps.
//
//   THE PROBLEM MOVES INTO THE ARC'S FRAME FOR FREE, because rotations are
//   linear: the ray's origin and direction go through the same roll and spin the
//   curve is defined in, and the direction stays unit because a rotation cannot
//   stretch it. In that frame the arc is a plain circle in a plane.
//   THE SEARCH RUNS ALONG THE CURVE, NOT THE RAY. For any point on the arc the
//   ray's closest approach to it is two dot products, so twenty samples along
//   the curve plus a parabolic refinement find where the ray passes nearest the
//   filament. Searching a smooth one-dimensional function is what makes this
//   stable: the samples slide continuously as the geometry moves, so nothing
//   pops, where sampling the ray made the answer depend on where the taps fell.
//   THE INTEGRAL IS THEN EXACT. Locally the curve is a straight line, and a
//   gaussian tube crossed by a ray at angle alpha integrates to w * sqrt(pi) /
//   sin(alpha) times the gaussian of the perpendicular distance.
//
// Once the sampling constraint is gone the width is a free design decision
// again, which is the whole point of the rewrite: at 0.052 the thread is five
// per cent of the sphere's radius, about five pixels at 120 pt and two at 18,
// and it is that because that is what reads as calligraphic -- not because
// anything downstream needs it to be.
//
// THE SPINDLE. Width and brightness fall away from the middle together, on one
// profile, so the thread is thickest and brightest at its centre and vanishes to
// a point at each tip. Brightness falls faster than width does, which reads as a
// stroke laid down with pressure in the middle and lifted at both ends. A
// filament of even width with a fade painted on its ends is a rod that got
// dimmer; one that NARROWS as it dims is a stroke.
//
// TWO CROSSINGS, because a shallow U seen from most angles is crossed twice --
// once through each limb -- and a global minimum would find only one and break
// the thread where it passes over itself. The arc is searched in halves and both
// winners contribute, with the second faded out by how far apart the two answers
// are, so the apex does not render at double brightness when both halves
// converge on it.
//
// CORE PIN (c2) IS THE ARC'S CLOSEST APPROACH TO THE CENTRE, and it is the knob
// the species is really about. At 1 the filament passes right through the core
// and the presence reads as one bright line struck through its own middle; at 0
// it bows well clear and reads as a thread hung across the volume. Everything
// between is the interesting part. THE ARC NEVER TOUCHES THE SHELL: its geometry
// is chosen so both ends land inside 0.70 at every setting of the knobs, which
// is comfortably inside mh_inside's fade, so it is a filament in glass rather
// than a wire soldered to the inside of it.
//
// LEVEL PUTS ENERGY IN THE LINE: voice brightens the filament and BOWS IT
// FURTHER, the way a plucked string carries more amplitude when it carries more
// energy. ACTIVITY RUNS CURRENT ALONG IT: a travelling brightness down the arc's
// length, gated by mh_aa so it retires itself at the sizes where a cycle would
// be under two pixels.
//
// RESPONDING PULLS IT TAUT. The bow flattens toward a straight chord and the
// travelling pulse becomes strong and regular: a slack thread going tight is
// about as legible a picture of "answering now" as a single line can make.
//
// THE GESTURE, every eight seconds or so: the arc bows deeper and a glimmer runs
// its whole length.
//
// SUCCESS: one bright pulse travels the filament end to end on the state's
// sweep, the whole line lifts under it, and it settles brighter.
//
// SIZE: at 18 pt the thread thickens by 90 per cent to hold the same pixel
// count, the span shortens by a fifth so what is left is a clean short curve
// rather than a long thin one, and the travelling current switches off. The
// closed-form integral scales with WIDTH, so the gain is cut by roughly the
// reciprocal of that widening -- without it the small mounts came out three
// times brighter than the large one. What survives is one soft bright stroke
// bowing inside a bead.
[[ stitchable ]] half4 mh_arc(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float lengthK  = clamp(c0, 0.0, 1.0);   // how far round the arc goes
    float swayK    = clamp(c1, 0.0, 1.0);   // how much its plane wanders
    float pinK     = clamp(c2, 0.0, 1.0);   // how near the core it passes
    float spreadK  = clamp(c3, 0.0, 1.0);   // hue along its length

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.021 + 0.007 * mh_breath(t, 6.1), 0.0, 1.20);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float4 fl = mh_flourish(t, 11.0, 8.1);

    // THE ARC'S FRAME. Rolled and tilted so the curve is seen from a changing
    // angle, swaying at a rate the sway knob sets. Responding stills the wander
    // and takes the bow out.
    float sway = (0.30 + 0.60 * swayK) * (1.0 - 0.55 * st.drive);
    float ro = 0.55 + sway * 0.9 * sin(mh_drift(t, 0.052, 0.5, 1.0));
    float ay = mh_drift(t, 0.041, 0.55, 2.0);
    float ax = 0.30 + sway * 0.5 * sin(t * 0.037 + 2.2);

    // THE GEOMETRY. The arc's midpoint sits `pin` from the centre on the bow
    // axis, the circle has radius Rc, so its centre is at (pin - Rc) along that
    // axis. Rc came DOWN and span went UP -- 0.65 by 1.33 rather than 0.83 by
    // 0.87 -- which is the same trade a draughtsman makes to get a longer line
    // out of a fixed sheet: a tighter circle carries more arc before its ends
    // run out to the edge. Length goes from 1.44 body units to about 1.72, and
    // the shape it draws is a shallow catenary U rather than a comma.
    float pin = mix(0.30, 0.05, pinK) * (1.0 + 0.30 * live.voice + 0.35 * fl.x)
              * (1.0 - 0.40 * st.drive);
    float Rc = (0.58 + 0.14 * lengthK) * S;
    float span = (1.15 + 0.35 * lengthK) * mix(1.0, 0.78, small);

    // In the arc's own frame the bow axis is +y and the arc opens along x.
    float cz = pin * S - Rc;

    // A THREAD, AND THE ONLY WAY TO GET ONE. 0.052 body units is five per cent
    // of the sphere's radius: about five pixels at 120 pt and two at 18 pt.
    //
    // The previous cut ran at 0.125 and the verdict was exactly right -- a fat
    // slug of light. It was that wide for a reason, though, and the reason is
    // worth recording because it is the constraint this rewrite had to break.
    // A marched filament cannot be thinner than the march: at ten steps down a
    // two-unit chord the interval is 0.2, so a tube narrower than that is caught
    // by whichever tap happens to land in it and missed otherwise, and the line
    // renders dim, uneven, and flickering as it moves. Widening it to 0.125 was
    // the only way to make ten taps honest. Sixteen taps would have bought 0.08,
    // which is still not a thread, at three times the cost.
    //
    // So the filament is no longer marched at all. See below: it is integrated
    // in closed form, and once the sampling constraint is gone the width is a
    // free design decision again. It is now set purely by what reads as
    // calligraphic, which is what it should have been set by all along.
    float w = (0.042 + 0.022 * lengthK) * S * mix(1.0, 1.90, small);
    float bright = (0.90 + 0.85 * live.voice) * (1.0 + 0.45 * fl.x);

    float shimGate = mh_aa(6.2831853 * 4.2 / (MH_R * S), size, pixelScale) * (1.0 - small);
    float shimAmt = shimGate * (0.55 * live.pace + 0.75 * st.drive);

    float medAmt = mix(0.055, 0.030, small);

    // THE FILAMENT, INTEGRATED RATHER THAN SAMPLED.
    //
    // Rotations are linear, so the whole problem moves into the arc's own frame
    // for free: the ray's origin and direction go through the same roll and spin
    // the curve is defined in, and the direction stays unit because a rotation
    // cannot stretch it. In that frame the arc is a plain circle in the xy plane
    // and everything below is two dimensions plus a z offset.
    //
    // For any point C on the curve, the ray's closest approach to it is two dot
    // products -- how far along the ray (sc) and how far off it (perp). Sampling
    // that at twelve points ALONG THE CURVE and taking the smallest finds where
    // the ray passes nearest the filament, and that is a search over a smooth
    // one-dimensional function rather than over the ray, which is what makes it
    // stable: the samples move continuously as the geometry moves, so nothing
    // pops. A parabola through the winner and its two neighbours then refines
    // the position to well inside a sample interval, which is what removes the
    // beading twelve discrete points would otherwise leave along the thread.
    //
    // With the nearest point known, the integral is closed form. Locally the
    // curve is a straight line, and the integral of a gaussian tube along a ray
    // crossing a line at angle alpha is w * sqrt(pi) / sin(alpha), times the
    // gaussian of the perpendicular distance. The 1 / sin(alpha) is the same
    // grazing amplification fathom's shells use and it is just as real here: a
    // ray running nearly along the filament passes through much more of it. The
    // floor at 0.30 caps that at a bit over three, because the exactly parallel
    // case is a division by zero.
    //
    // TWO CROSSINGS, because a U seen from many angles is crossed twice -- once
    // through each limb -- and a global minimum would find only one and break
    // the thread where it passes over itself. So the arc is searched in halves
    // and both winners contribute. When both halves converge on the same place,
    // which is what happens near the apex, the second is faded out by how far
    // apart the two answers are; otherwise the apex would render at double
    // brightness.
    float3 Pa = mh_spin(mh_roll(b.P, ro), ay, ax);
    float3 Ra = mh_spin(mh_roll(rd, ro), ay, ax);

    const int NS = 20;
    float gv[NS], tv[NS], sv[NS];
    for (int i = 0; i < NS; i++) {
        float th = -span + (2.0 * span) * (float(i) / float(NS - 1));
        float3 C = float3(Rc * sin(th), cz + Rc * cos(th), 0.0);
        float3 D = C - Pa;
        float sc = dot(D, Ra);
        gv[i] = dot(D, D) - sc * sc;
        tv[i] = th;
        sv[i] = sc;
    }

    float dth = (2.0 * span) / float(NS - 1);
    float filE = 0.0, filH = 0.0, thPick[2];
    thPick[0] = 0.0; thPick[1] = 0.0;
    float partE[2]; partE[0] = 0.0; partE[1] = 0.0;

    for (int hf = 0; hf < 2; hf++) {
        int lo = hf * 10, hi = lo + 9;
        int bi = lo;
        for (int i = lo + 1; i <= hi; i++) { if (gv[i] < gv[bi]) bi = i; }

        // Parabolic refinement, with the sample index pulled inside the array so
        // the three-point fit always has its neighbours.
        int ci = clamp(bi, 1, NS - 2);
        float y0 = gv[ci - 1], y1 = gv[ci], y2 = gv[ci + 1];
        float den = y0 - 2.0 * y1 + y2;
        float off = (abs(den) > 1e-7) ? clamp(0.5 * (y0 - y2) / den, -1.0, 1.0) : 0.0;
        float th = clamp(tv[ci] + off * dth, -span, span);

        float3 C = float3(Rc * sin(th), cz + Rc * cos(th), 0.0);
        float3 D = C - Pa;
        float sc = dot(D, Ra);
        float perp2 = max(dot(D, D) - sc * sc, 0.0);
        thPick[hf] = th;
        if (sc <= 0.0 || sc >= L) continue;

        // THE SPINDLE. Width and brightness both fall away from the middle on
        // one profile, so the thread is thickest and brightest at its centre and
        // vanishes to a point at each tip. A filament of even width with a fade
        // painted on its ends is a rod that got dimmer; a filament that NARROWS
        // as it dims is a stroke, and the difference is the whole verdict.
        float u = clamp(abs(th) / max(span, 1e-3), 0.0, 1.0);
        float prof = pow(max(1.0 - u * u, 0.0), 0.85);
        float wl = w * (0.28 + 0.72 * prof);

        // The angle between the ray and the curve's tangent, in the arc frame.
        // The floor is 0.58 rather than the 0.30 the geometry would allow: the
        // 1 / sin(alpha) amplification is real -- a ray running along the thread
        // passes through more of it -- but at three and a third it put a bright
        // BULGE wherever the filament happened to lean toward the viewer, and a
        // thread with a swelling two thirds of the way along it is not brightest
        // at its centre, which is the whole of the brief. Capped at 1.7 the cue
        // survives as a gentle thickening and the spindle keeps its shape.
        float3 T = float3(cos(th), -sin(th), 0.0);
        float sinA = max(length(cross(Ra, T)), 0.58);

        // Current along the length, and the pulses that ride it.
        float run = 1.0;
        if (shimAmt > 0.002) run += shimAmt * sin(th * 4.2 - t * 2.4);
        float pulse = 0.0;
        if (fl.x > 0.002) {
            float pr = (th - mix(-span, span, fl.y)) / 0.34;
            pulse += fl.x * 0.95 * exp(-pr * pr);
        }
        if (st.complete > 0.001) {
            float pr = (th - mix(-span, span, st.sweep)) / 0.30;
            pulse += st.complete * 1.80 * exp(-pr * pr);
        }

        float ws = wl / sqrt(MH_SCATTER_K);          // the scatter's own width
        const float SQRTPI = 1.7724539;
        float core = (wl * SQRTPI / sinA) * exp(-perp2 / (wl * wl));
        // The halo's coefficient is 0.09, not the 0.24 the other heroes give
        // their scatter, and the reason is that this one is INTEGRATED rather
        // than sampled. The integral scales with width, so a halo 3.2 times
        // wider than the core carries 3.2 times the light at the same
        // coefficient -- it stopped being a glow around a thread and became a
        // wide band with a thread inside it, which at the small mounts filled
        // half the sphere. At 0.09 the core is what reaches the rail's top and
        // the halo sits an octave below it, which is what a soft thread in glass
        // actually looks like.
        float halo = 0.09 * (ws * SQRTPI / sinA) * exp(-perp2 / (ws * ws));

        float vis = mh_inside(Pa + Ra * sc) * exp(-MH_EXT * sc);
        // Brightness falls off the centre faster than width does -- pow 1.35
        // against the width's linear ride on the same profile -- so the thread
        // reads as a stroke laid down with pressure in the middle and lifted at
        // both ends, rather than as a rod of even ink that happens to narrow.
        float e = (core + halo) * pow(prof, 1.35) * bright * run * (1.0 + pulse) * vis;

        partE[hf] = e;
        filH += e * clamp(th / max(span, 1e-3), -1.0, 1.0);
    }

    // When the two halves land in the same place the second is a duplicate of
    // the first, not a second crossing.
    float sep = smoothstep(0.16, 0.44, abs(thPick[0] - thPick[1]));
    filE = partE[0] + partE[1] * sep;
    filH = (partE[0] * clamp(thPick[0] / max(span, 1e-3), -1.0, 1.0)
          + partE[1] * sep * clamp(thPick[1] / max(span, 1e-3), -1.0, 1.0));

    // The medium, still marched, and at the family's five taps: it is broad, so
    // five is honest for it, and it carries the only noise this hero reads.
    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);
    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;
        float e = mh_medium(p, t, 2.0 / S) * medAmt;
        acc.x += e * trans * ds;
        trans *= exp(-(2.00 * e + MH_EXT) * ds);
    }

    float interior = // The closed-form integral scales with the thread's WIDTH, and the small mounts
    // widen it by 2.6 to hold the same pixel count -- so without this the 18 pt
    // tile came out three times brighter than the 300 pt one and blew straight
    // through the top of the rail. The compensation is the reciprocal of the
    // widening, which is what keeps one hero looking like one hero at every
    // mount.
    (acc.x * 3.40 + filE * 35.0 * mix(1.0, 0.52, small)) * b.m * mh_transmit(b.fres)
                   * (1.0 + 0.9 * st.complete) * (1.0 + 0.22 * st.settled);
    float hue = (filE > 1e-5 ? filH / filE : 0.0) * spreadK * MH_SPREAD;

    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.80 + 0.35 * live.voice, 0.30, 0.14);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (filE * 35.0 * mix(1.0, 0.52, small)) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(interior + sf.rim, sf.spec, sf.glow, hueMix,
                      uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 11. Opal

// OPAL. Internal play-of-colour: soft flashes drifting through the volume.
//
// NO STROBE, EVER, and that is the constraint the whole species is built around.
// Play-of-colour in a real opal is not a flicker; it is a slow shifting of where
// the light is coming from as the stone turns, and the eye reads it as depth
// rather than as an event. So every flash here is BORN AND ABSORBED SLOWLY: each
// one rides its own life envelope on a period between fourteen and twenty-two
// seconds, out of phase with the others, so no two arrive together and none of
// them ever appears or vanishes -- they come up out of the glass and go back
// into it. The envelope also has a floor rather than a zero, so a flash at its
// dimmest is still faintly present and there is no moment of switching on.
//
// FOUR FLASHES, SOLVED AT CLOSEST APPROACH. They are compact bodies, so five
// marched samples would draw the shape of the sampling; two dot products each
// draws the shape of the flash, perfectly round from any angle and stable as it
// moves. Each carries the kit's scatter at a generous amplitude, because a
// flash inside an opal is mostly the glow it throws into the stone around it
// rather than the bright centre -- the scatter is the species here, not a
// finish on it.
//
// SPREAD DOES ITS WIDEST WORK, which is why this hero carries the collection's
// highest default and the one internal multiplier above the family cap. The four
// flashes sit at four points across the spread -- two either side of the anchor
// -- and at the default they are already four distinguishable neighbours. The
// multiplier takes the extremes to about thirty-seven degrees of OKLAB hue at
// spread 1, which is amber to gold on one side and amber to ember on the other:
// still one hue family by the rail's own definition, still nothing that could be
// called a second colour, and the widest this collection ever goes. Play-of-
// colour is the species; anywhere else this would be too much.
//
// LEVEL BLOOMS THEM: voice grows each flash and brightens it, so a room with
// somebody in it has a stone with more fire. ACTIVITY QUICKENS THE DRIFT, and
// only the drift -- cadence moves the flashes around, it does not light them,
// because the two signals doing different things is what lets a person read
// which one is happening.
//
// RESPONDING TURNS THEM INTO A PROCESSION. The drift directions align and the
// flashes brighten in sequence along that axis, so what was four lights waking
// at random becomes a wave of colour crossing the volume one way.
//
// SUCCESS: all four ignite together and settle, which is the only moment in the
// species where they are ever in phase -- and it reads as an event precisely
// because nothing else here ever is.
//
// SIZE: at 18 pt two flashes crossfade away and the two that remain are 70 per
// cent larger, because four soft blobs in a thirteen-point bead is a texture and
// two is a composition. What survives is one warm light and one cool one moving
// slowly past each other, which is play-of-colour said in two marks.
[[ stitchable ]] half4 mh_opal(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float flashK   = clamp(c0, 0.0, 1.0);   // how strong the fire is
    float driftK   = clamp(c1, 0.0, 1.0);   // how fast they wander
    float softK    = clamp(c2, 0.0, 1.0);   // how diffuse each one is
    float spreadK  = clamp(c3, 0.0, 1.0);   // the play of colour itself

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.022 + 0.008 * mh_breath(t, 7.4), 0.0, 1.22);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float4 fl = mh_flourish(t, 13.0, 10.6);

    float drift = (0.055 + 0.075 * driftK) * (1.0 + 0.75 * live.pace + 0.95 * st.drive);
    float rad = (0.135 + 0.095 * softK) * S * mix(1.0, 1.70, small)
              * (1.0 + 0.30 * live.voice);
    float bright = (0.82 + 0.55 * flashK) * (1.0 + 0.85 * live.voice);

    // Two flashes crossfade away at the small mounts.
    float pairB = 1.0 - smoothstep(0.30, 0.72, small);

    // THE WIDEST SPREAD IN THE COLLECTION. See the header for why this species
    // gets a multiplier the others do not.
    float spreadAmt = spreadK * MH_SPREAD * 1.30;

    float flashE = 0.0, flashH = 0.0;

    for (int k = 0; k < 4; k++) {
        float w = (k < 2) ? 1.0 : pairB;
        if (w < 0.002) continue;
        float fk = float(k);

        // THE LIFE. Periods 14.3, 17.1, 19.6 and 22.4 seconds, mutually
        // incommensurate and phase-offset, so the four are never in step and no
        // gap between arrivals repeats. sin^2 for flat ends -- nothing switches
        // on -- and a floor of 0.16 so the dimmest is still in the stone.
        float per = 14.3 + 2.7 * fk;
        float ph = fk * 1.97;
        float sn = sin(6.2831853 * t / per + ph);
        float life = 0.16 + 0.84 * sn * sn;
        // Responding brightens them in sequence along the procession axis.
        life = mix(life, 0.30 + 0.70 * max(sin(6.2831853 * t / 5.2 - fk * 1.4), 0.0), st.drive);
        life = mix(life, 1.0, st.complete * 0.85);

        // THE WANDER. Three incommensurate rates per flash, so each traces its
        // own slow closed-ish path and none of them repeats against another.
        float3 c = float3(0.44 * sin(drift * t * (0.83 + 0.11 * fk) + fk * 2.1),
                          0.40 * sin(drift * t * (0.67 + 0.13 * fk) + fk * 3.7 + 1.1),
                          0.42 * sin(drift * t * (0.95 + 0.09 * fk) + fk * 1.3 + 2.6));
        // Under drive they all lean the same way: a procession, not a swarm.
        c = mix(c, c * 0.55 + float3(0.42, -0.10, 0.18) * sin(6.2831853 * t / 5.2 - fk * 1.4),
                st.drive);

        float rk = rad * (0.80 + 0.30 * fract(fk * 0.37 + 0.21)) * (1.0 + 0.35 * fl.x * step(fk, 0.5));

        float3 to = c - b.P;
        float s = dot(to, rd);
        if (s <= 0.0 || s >= L) continue;
        float arg = max(dot(to, to) - s * s, 0.0) / max(rk * rk, 1e-6);
        float vis = mh_inside(b.P + rd * s) * exp(-MH_EXT * s);
        // The scatter carries most of the light: a flash in an opal is the glow
        // it throws into the stone more than it is its own centre.
        float e = (exp(-arg) * 0.55 + mh_scatter(arg, 0.46)) * vis * life * bright * w;

        flashE += e;
        // The four hues, two either side of the anchor.
        float hueK = (fk - 1.5) / 1.5;
        flashH += e * hueK;
    }

    float medAmt = mix(0.060, 0.032, small);
    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);
    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;
        float e = mh_medium(p, t, 2.1 / S) * medAmt;
        if (st.complete > 0.001) {
            float sr = (length(p) - mix(0.02, 1.0, st.sweep)) / 0.24;
            e += st.complete * 0.30 * exp(-sr * sr);
        }
        acc.x += e * trans * ds;
        trans *= exp(-(2.00 * e + MH_EXT) * ds);
    }

    float interior = (acc.x * 3.40 + flashE) * b.m * mh_transmit(b.fres)
                   * (1.0 + 0.22 * st.settled);
    float hue = (flashE > 1e-4 ? flashH / flashE : 0.0) * spreadAmt;

    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.80 + 0.35 * live.voice, 0.52, 0.14);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * flashE / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(interior + sf.rim, sf.spec, sf.glow, hueMix,
                      uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 12. Flux

// FLUX. An aurora streaming inside the glass.
//
// THE ONE HERO ALLOWED A BROAD FLOWING FIELD, and it needs the permission
// because an aurora is not an object. Everything else in this collection is
// something IN the glass -- a point, a heart, a pair, a filament, shells,
// flashes -- or, in nebula's case, weather that fills it. This is the only one
// whose interior is a field with a direction: curtains hanging vertically,
// bending as they stream sideways, which is a shape the rest of the family has
// no vocabulary for.
//
// A CURTAIN IS A VERTICAL SHEET WHOSE POSITION WANDERS WITH HEIGHT AND DEPTH,
// which is one line: the sheet sits at x equal to a sum of two slow waves read
// in y and z, and the density is a gaussian in the distance from it. Two
// incommensurate waves rather than one, because a single wave is a corrugation
// and reads as machined. Three curtains at three offsets with three phases give
// the stacked, overlapping look that makes an aurora read as a curtain rather
// than as a stripe.
//
// AURORAE ARE BRIGHT AT THE BOTTOM AND FADE UPWARD, and getting that one profile
// right is most of what makes this read as an aurora rather than as a vertical
// smear. The lower edge is where the atmosphere is dense enough to glow hard;
// above it the light thins out over several times that height. So the vertical
// term is a sharp rise at the foot and a long exponential decay above it, and it
// is asymmetric on purpose -- a symmetric profile reads as a band of light and
// not as a curtain hanging.
//
// THE STRIATION is the fine vertical structure real curtains have: a gentle
// modulation across the sheet, gated by mh_aa so it retires itself the moment a
// cycle would be under two pixels. It is the thing that makes the large mount
// worth watching and the first thing the small mount gives up.
//
// LEVEL RAISES THE CURTAINS: voice extends their height and brightens them,
// which is the most literal thing an aurora can do with energy and the right one
// -- a louder room gets a taller display. ACTIVITY QUICKENS THE STREAMING, so
// cadence moves the curtains sideways faster and bends them harder as they go.
//
// RESPONDING MAKES THEM LEAN AND RUN ONE WAY. The bend phases align, the drift
// doubles, and the whole display streams in a single direction instead of
// wandering -- an aurora with a wind in it.
//
// THE GESTURE, every eleven seconds or so: a brightening surge travels across
// the curtains from one side to the other. Auroral substorm, in miniature.
//
// SUCCESS: the surge runs the full width on the state's sweep and every curtain
// lifts under it, then settles brighter.
//
// SIZE: at 18 pt two curtains crossfade away, the one that remains is twice as
// wide and its bend is halved, and the striation is gone. What survives is a
// single broad band of light leaning through a warm bead -- which is the least
// an aurora can be and still be streaming.
[[ stitchable ]] half4 mh_flux(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float streamK = clamp(c0, 0.0, 1.0);   // how fast the curtains travel
    float bendK   = clamp(c1, 0.0, 1.0);   // how hard they fold
    float heightK = clamp(c2, 0.0, 1.0);   // how far up they reach
    float spreadK = clamp(c3, 0.0, 1.0);   // the curtains' hues

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.022 + 0.008 * mh_breath(t, 8.6), 0.0, 1.22);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float4 fl = mh_flourish(t, 15.0, 11.3);

    // The display turns slowly so the curtains are never seen from the same
    // angle twice; responding stills the turn and leans it.
    float ay = mix(mh_drift(t, 0.047, 0.50, 2.0), 0.42, st.drive * 0.6);
    float ax = 0.16 + 0.10 * sin(t * 0.033);

    float flow = mh_drift(t, 0.26 + 0.34 * streamK, 0.45, 4.0)
               * (1.0 + 0.70 * live.pace + 0.95 * st.drive);
    float bend = (0.30 + 0.42 * bendK) * (1.0 + 0.45 * live.pace) * mix(1.0, 0.50, small);

    // Sheet thickness, and the widths that keep the read the same at both ends.
    float w = (0.105 + 0.030 * bendK) * S * mix(1.0, 2.00, small);
    float hi = (0.42 + 0.46 * heightK) * (1.0 + 0.45 * live.voice);

    float second = 1.0 - smoothstep(0.34, 0.76, small);
    float third  = 1.0 - smoothstep(0.16, 0.54, small);
    float bright = (0.80 + 0.80 * live.voice) * (1.0 + 0.35 * st.drive);

    float striGate = mh_aa(6.2831853 * 6.5 / (MH_R * S), size, pixelScale) * (1.0 - small);

    float medAmt = mix(0.055, 0.030, small);

    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        float3 q = mh_spin(p, ay, ax) / S;

        // UP IS NEGATIVE Y. A colorEffect's y runs DOWN the screen, so the body
        // frame's +y is the bottom of the picture -- and the first cut hung its
        // curtains from that, which put the bright foot along the TOP and the
        // fade going down. An upside-down aurora is not a subtle mistake; it
        // reads as light pouring in from above rather than as curtains standing
        // on something. One negation fixes it, and every use of height below
        // reads this rather than q.y.
        float yy = -q.y;

        // THE VERTICAL PROFILE, shared by all three curtains: a sharp foot and a
        // long fade upward. `hi` is how far the light reaches above the foot.
        float foot = smoothstep(-0.92, -0.52, yy);
        float rise = exp(-max(yy + 0.52, 0.0) / max(hi, 1e-3));
        float vert = foot * rise;

        // Three sheets. Each wanders at its own pair of frequencies, and their
        // phases are offset so they overlap rather than nest.
        // The wander is deliberately weighted toward DEPTH rather than height.
        // A sheet whose position swings hard with height leans, and three leaning
        // sheets read as diagonal streaks rather than as curtains hanging; the
        // same swing read in z folds the curtain toward and away from the viewer,
        // which is what an aurora does and what the eye reads as a fold rather
        // than as a slant. So the height terms run at 1.1 and the depth terms
        // carry the larger share.
        float d0 = q.x - (-0.34 + bend * (0.55 * sin(1.10 * yy + flow) + 0.95 * sin(1.15 * q.z - flow * 0.7 + 2.1)));
        float d1 = q.x - ( 0.04 + bend * (0.55 * sin(0.85 * yy + flow * 1.18 + 2.4) + 1.00 * sin(1.55 * q.z - flow * 0.6 + 4.3)));
        float d2 = q.x - ( 0.40 + bend * (0.55 * sin(1.35 * yy + flow * 0.86 + 4.7) + 0.90 * sin(0.95 * q.z - flow * 0.9 + 1.4)));

        float a0 = (d0 * d0) / (w * w);
        float a1 = (d1 * d1) / (w * w * 1.25);
        float a2 = (d2 * d2) / (w * w * 0.85);

        float e0 = (exp(-a0) + mh_scatter(a0, 0.20));
        float e1 = (exp(-a1) + mh_scatter(a1, 0.20)) * second;
        float e2 = (exp(-a2) + mh_scatter(a2, 0.20)) * third;

        // The striation: fine vertical structure across the sheets.
        float stri = 1.0;
        if (striGate > 0.002) {
            stri += striGate * 0.32 * sin(q.z * 6.5 + yy * 1.7 - flow * 1.4);
        }

        // The surge, and success running it the whole width.
        float surge = 0.0;
        if (fl.x > 0.002) {
            float sr = (q.x - mix(-0.9, 0.9, fl.y)) / 0.42;
            surge += fl.x * 0.85 * exp(-sr * sr);
        }
        if (st.complete > 0.001) {
            float sr = (q.x - mix(-1.0, 1.0, st.sweep)) / 0.38;
            surge += st.complete * 1.70 * exp(-sr * sr);
        }

        float curtains = (e0 + e1 + e2) * vert * bright * stri * (1.0 + surge);
        // The three curtains at three hues, weighted by which one is here.
        float hueW = (e0 * -1.0 + e1 * 0.15 + e2 * 1.0) * vert * bright * stri;

        float med = mh_medium(p, t, 2.1 / S) * medAmt;
        float e = (curtains * 0.85 + med) * fade;

        acc.x += e * trans * ds;
        acc.y += hueW * 0.85 * fade * trans * ds;
        trans *= exp(-(2.90 * e + MH_EXT) * ds);
    }

    float interior = acc.x * 2.40 * b.m * mh_transmit(b.fres)
                   * (1.0 + 0.75 * st.complete) * (1.0 + 0.22 * st.settled);
    float hue = (acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD;

    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.80 + 0.35 * live.voice, 0.55, 0.14);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(interior + sf.rim, sf.spec, sf.glow, hueMix,
                      uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 13. Tempest

// TEMPEST. A contained storm: weather churning, with lightning buried in it.
//
// NEBULA'S SIBLING AND ITS OPPOSITE TEMPERAMENT. Both are weather and both are
// domain-warped mist, and everything else about them differs. Nebula is lit
// evenly from within and its business is depth: near folds silhouetting against
// a deep glow. This one is lit from INSIDE ITS OWN FLASHES, its density runs
// harder so the cloud has real dark in it, and its business is energy: a body
// that is calm when nothing is happening and visibly working when something is.
//
// THE FLICKERS LIVE DEEP AND NEVER REACH THE SURFACE, which is the species'
// one inviolable rule and the difference between a storm in a jar and a
// novelty lamp. Two things enforce it. A depth mask kills any flash outside
// 0.62 of the radius outright, so nothing can ignite near the shell. And the
// flashes are evaluated INSIDE the march, so the cloud in front of them
// attenuates them exactly as it attenuates everything else -- what reaches the
// eye is a glow diffused through weather rather than a light with an edge. A
// flash solved outside the loop, the way comet's head is, would sit on top of
// the cloud and the species would be over.
//
// AND THEY DO NOT STROBE. The envelope is the flourish clock's sin-squared,
// which is flat at both ends, over a gesture lasting most of a second: it
// arrives and it leaves, and there is no frame where it switches. Two lanes at
// 2.9 and 4.3 second slots interleave without ever landing together, so the
// storm has an irregular pulse rather than a beat. At rest the lanes are slow
// enough that minutes pass quietly.
//
// ACTIVITY IS THE STORM, and this is the deepest reading of cadence in the
// collection. It raises the churn, quickens the weather, and shortens both
// flicker slots -- so an assistant that is working has visible turbulence and
// lightning in it, and one that is idle is a calm dark cloud. THINKING adds to
// the same term on top of the signal, because that state is the one this
// species was built to wear. LEVEL LIGHTS THE CLOUD: voice lifts the ambient
// glow without touching the churn, so speaking makes the weather visible rather
// than making it worse.
//
// RESPONDING GIVES THE STORM A HEADING: the whole domain advects one way and the
// flickers stop wandering, so churning becomes streaming.
//
// SUCCESS: the cloud ignites from the inside and a front travels out through it.
//
// SIZE: at 18 pt the noise scale halves so the folds are features rather than
// grain, the warp comes down with it, and the flickers grow by two thirds and
// come round half as often -- one soft flash inside a dark bead every several
// seconds, which is the species in the fewest events it can have.
[[ stitchable ]] half4 mh_tempest(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float stormK   = clamp(c0, 0.0, 1.0);   // how much weather there is
    float churnK   = clamp(c1, 0.0, 1.0);   // how hard it turns over
    float flickerK = clamp(c2, 0.0, 1.0);   // the buried lightning
    float spreadK  = clamp(c3, 0.0, 1.0);

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    // THINKING IS THIS SPECIES' HOME STATE, so it is read directly rather than
    // through mh_state, which only designs success and responding. A storm that
    // rises while the assistant thinks is the whole concept.
    float think = (stateIndex > 1.5 && stateIndex < 2.5) ? 1.0 : 0.0;
    float energy = clamp(0.85 * live.pace + 0.65 * think + 0.55 * st.drive, 0.0, 1.6);

    MHShape sh = mh_shape(0.023 + 0.009 * mh_breath(t, 9.2), 0.0, 1.28);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float scale = (2.55 / S) * mix(1.0, 0.55, small);
    float warpScale = (1.45 / S) * mix(1.0, 0.58, small);
    float fold = (0.42 + 0.80 * churnK) * (1.0 + 0.85 * energy) * mix(1.0, 0.50, small);
    float dr = mh_drift(t, 0.070 + 0.075 * churnK, 0.42, 3.0) * (1.0 + 0.95 * energy);
    float3 adv = float3(0.88, 0.20, -0.43) * (st.drive * 0.50 * t);

    float absorb = 3.60 * (0.55 + 0.85 * stormK);
    float emit = 0.58 + 0.72 * stormK;

    // TWO LIGHTNING LANES, on slots that shorten as the storm rises.
    float rate = 1.0 / (1.0 + 1.30 * energy);
    float4 f0 = mh_flourish(t, 21.0, mix(2.9, 5.2, small) * rate);
    float4 f1 = mh_flourish(t, 27.0, mix(4.3, 7.4, small) * rate);
    float fw = (0.150 + 0.070 * flickerK) * S * mix(1.0, 1.65, small);
    float fAmp = (0.85 + 2.80 * flickerK) * (1.0 + 0.45 * energy);

    float3 g0 = 0.40 * float3(cos(f0.z * 6.283), 0.75 * sin(f0.z * 9.1 + 1.1), sin(f0.z * 5.3 + 2.7));
    float3 g1 = 0.40 * float3(cos(f1.z * 7.7 + 2.2), 0.75 * sin(f1.z * 6.4 + 3.9), sin(f1.z * 8.8 + 0.4));

    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        float w = mh_noise3(p * warpScale + float3(0.0, dr * 0.65, dr) - adv * 0.5);
        float3 q = p * scale + w * fold * float3(0.90, -0.62, 0.68)
                 + float3(0.0, 0.0, dr) - adv;
        float n = mh_noise3(q);

        // Harder than nebula's: the lower edge sits further up, so the cloud has
        // real holes and the flashes have somewhere dark to be seen against.
        float dens = smoothstep(-0.12, 0.46, n) * fade;

        float glowIn = 0.26 + 0.72 * (1.0 - smoothstep(0.0, 0.90, length(p)));
        float e = dens * glowIn * emit * (1.0 + 0.85 * live.voice);

        // THE BURIED LIGHTNING. Depth-masked to the inner two thirds, so it can
        // never light the shell, and inside the march so the weather in front of
        // it does the diffusing.
        float deep = 1.0 - smoothstep(0.35, 0.62, length(p));
        if (deep > 0.002) {
            float3 d0 = (p - g0) / max(fw, 1e-3);
            float3 d1 = (p - g1) / max(fw, 1e-3);
            float a0 = dot(d0, d0), a1 = dot(d1, d1);
            // MOSTLY SCATTER, and much more of it than any other hero's: a
            // flash inside a cloud is seen almost entirely as the cloud lighting
            // up, not as the flash. At the first cut's balance the core won and
            // what drew was a bright dot with weather around it -- a bulb in
            // fog rather than lightning in it.
            float bolt = f0.x * (exp(-a0) * 0.42 + mh_scatter(a0, 0.62))
                       + f1.x * (exp(-a1) * 0.42 + mh_scatter(a1, 0.62));
            // Weighted by the local density: lightning lights the CLOUD, so it
            // is brightest where there is something for it to light.
            e += bolt * fAmp * deep * (0.30 + 0.85 * dens);
        }

        if (st.complete > 0.001) {
            float sr = (length(p) - mix(0.02, 1.05, st.sweep)) / 0.24;
            e *= 1.0 + 0.70 * st.complete;
            e += st.complete * 0.55 * exp(-sr * sr) * dens;
        }

        acc.x += e * trans * ds;
        acc.y += e * clamp(p.z, -1.0, 1.0) * trans * ds;
        trans *= exp(-(absorb * dens + MH_EXT) * ds);
    }

    float interior = acc.x * 6.20 * b.m * mh_transmit(b.fres) * (1.0 + 0.20 * st.settled);
    float hue = (acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD;

    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.80 + 0.35 * live.voice, 0.66, 0.15);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(interior + sf.rim, sf.spec, sf.glow, hueMix,
                      uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 14. Helix

// HELIX. A double strand of light, slowly climbing and turning.
//
// THE DISTANCE TO A HELIX, CHEAPLY. There is no closed form for the nearest
// point on a helix, but there is a very good approximation that costs one
// atan2: read the sample's own angle and radius about the helix axis, work out
// what angle the strand is at THAT HEIGHT, and take the wrapped difference. The
// lateral distance is that angle difference times the radius; the radial
// distance is how far the sample is off the strand's cylinder. Adding them in
// quadrature is exact for a strand of zero pitch and off by a factor of the
// cosine of the pitch angle for a real one -- which at the pitches this species
// uses is under a tenth, and is absorbed into the width. The wrap is what makes
// it work at all: without it the strand tears open along one radius, which is
// the same seam limn's arc and comet's trail each had to be rebuilt to avoid.
//
// TAPERED LIKE ARC'S THREAD, and for the same reason: a strand of even width
// running out of the top of the body reads as a cut cable. Both ends fall away
// on a profile in height, so the pair emerges out of the glass and returns into
// it, and the strands never touch the shell.
//
// EIGHT STEPS RATHER THAN FIVE. The strands are narrower than a sheet and
// broader than arc's filament, which puts them exactly in the gap where five
// taps step over them and a closed-form integral is not available. Eight is the
// smallest count that samples a 0.095 strand honestly, and this species can
// afford it because its distance function is trigonometry rather than noise.
//
// THE TWO STRANDS ARE THE DUOTONE'S NATURAL HOME. They sit half a turn apart
// and at opposite ends of the spread axis, so with one anchor they are two
// neighbours of the tone and with two they are the two anchors themselves,
// climbing around each other. Nothing else in the collection states a
// two-colour configuration as plainly.
//
// LEVEL FEEDS THE STRANDS: voice brightens and thickens them, which on a form
// this linear reads as the light in a filament being turned up. ACTIVITY
// QUICKENS THE CLIMB, so cadence moves the pattern up through the body faster
// without changing its shape.
//
// RESPONDING WINDS IT TIGHTER: the turn count rises by half and the climb
// nearly doubles. A helix under drive is visibly more coiled, which is about as
// direct a picture of effort as a geometric form can give.
//
// THE GESTURE, every nine seconds or so: the whole helix draws in and winds
// tighter, then relaxes.
//
// SUCCESS: a bright pulse climbs both strands to the top on the state's sweep.
//
// SIZE: at 18 pt the turns drop from about three to one and a half and the
// strands thicken by 80 per cent -- three turns of a thin strand inside a
// thirteen-point bead is a texture, and one and a half turns of a fat one is a
// double helix. The climb also slows a third, because the same rate over a
// shorter visible run reads as faster than it is.
[[ stitchable ]] half4 mh_helix(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float turnsK  = clamp(c0, 0.0, 1.0);   // how many turns across the body
    float riseK   = clamp(c1, 0.0, 1.0);   // how fast it climbs
    float glowK   = clamp(c2, 0.0, 1.0);   // the strands' light
    float spreadK = clamp(c3, 0.0, 1.0);   // the two strands' hues

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.021 + 0.007 * mh_breath(t, 10.4), 0.0, 1.20);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float4 fl = mh_flourish(t, 17.0, 9.3);

    // The axis leans and turns slowly, so the helix is never seen from the same
    // angle twice and its pole is never a landmark.
    float ay = mh_drift(t, 0.055, 0.50, 2.0);
    float ax = 0.22 + 0.13 * sin(t * 0.031);

    float turns = (1.7 + 2.2 * turnsK) * mix(1.0, 0.52, small)
                * (1.0 + 0.50 * st.drive + 0.30 * fl.x);
    float climb = mh_drift(t, (0.22 + 0.34 * riseK) * mix(1.0, 0.66, small), 0.44, 5.0)
                * (1.0 + 0.75 * live.pace + 0.85 * st.drive);
    float r0 = (0.40 + 0.10 * turnsK) * S * (1.0 - 0.16 * st.drive - 0.12 * fl.x);
    float w = (0.095 + 0.030 * glowK) * S * mix(1.0, 1.80, small)
            * (1.0 + 0.30 * live.voice);
    float bright = (0.72 + 0.60 * glowK) * (1.0 + 0.80 * live.voice);

    float medAmt = mix(0.055, 0.030, small);

    // FOURTEEN STEPS FOR THE STRANDS, FIVE FOR THE MEDIUM, and splitting them is
    // what fixed this species. At eight shared steps the interval was 0.25 and
    // the strands are 0.22 across, so a ray crossed one between taps as often as
    // through them: what drew was a DASHED helix, a stack of disconnected
    // streaks that read as stripes rather than as two continuous strands
    // climbing. Fourteen halves the interval and the strands close up.
    //
    // They can be afforded because this loop reads no noise at all -- the
    // distance to a helix is trigonometry -- so fourteen of these cost less than
    // the eight shared steps did. The medium keeps the family's five, which is
    // honest for something that broad, and carries the only noise here.
    const int STRANDS = 14;
    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(STRANDS);

    for (int i = 0; i < STRANDS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        float3 q = mh_spin(p, ay, ax) / S;
        float rho = length(q.xz);
        float th = atan2(q.z, q.x);

        // Where the strands are at this height. The second is half a turn round.
        float phi = turns * q.y * 3.14159265 + climb;

        // THE TAPER, in height: the pair emerges from the glass and returns to
        // it rather than being cut off by the shell.
        float hp = 1.0 - smoothstep(0.30, 0.86, abs(q.y));

        float dr0 = rho - r0;
        float aw0 = th - phi;
        aw0 = aw0 - 6.2831853 * floor(aw0 / 6.2831853 + 0.5);
        float lat0 = rho * aw0;
        float a0 = (dr0 * dr0 + lat0 * lat0) / (w * w);

        float aw1 = th - phi - 3.14159265;
        aw1 = aw1 - 6.2831853 * floor(aw1 / 6.2831853 + 0.5);
        float lat1 = rho * aw1;
        float a1 = (dr0 * dr0 + lat1 * lat1) / (w * w);

        // SUCCESS climbs the strands: a bright band travels up the pair.
        float lift = 1.0;
        if (st.complete > 0.001) {
            float sr = (q.y - mix(-1.0, 1.0, st.sweep)) / 0.26;
            lift += st.complete * (0.35 + 2.10 * exp(-sr * sr));
        }

        float e0 = (exp(-a0) + mh_scatter(a0, 0.20)) * hp;
        float e1 = (exp(-a1) + mh_scatter(a1, 0.20)) * hp;
        float strands = (e0 + e1) * bright * lift;

        // The two strands at the two ends of the spread axis, which under
        // duotone is the two anchors themselves.
        float hueW = (e1 - e0) * bright * lift;

        float e = strands * 0.80 * fade;
        acc.x += e * trans * ds;
        acc.y += hueW * 0.80 * fade * trans * ds;
        trans *= exp(-(3.00 * e + MH_EXT) * ds);
    }

    // The medium, at the family's five.
    float medE = 0.0;
    float mtrans = 1.0;
    float mds = L / float(MH_TAPS);
    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * mds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;
        float e = mh_medium(p, t, 2.1 / S) * medAmt;
        medE += e * mtrans * mds;
        mtrans *= exp(-(2.00 * e + MH_EXT) * mds);
    }
    acc.x += medE;

    float interior = acc.x * 4.20 * b.m * mh_transmit(b.fres) * (1.0 + 0.22 * st.settled);
    float hue = (acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD;

    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.80 + 0.35 * live.voice, 0.48, 0.14);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(interior + sf.rim, sf.spec, sf.glow, hueMix,
                      uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 15. Geode

// GEODE. Crystalline facets inside the glass, catching light as the body turns.
//
// A FACET IS A DIRECTION, NOT A POLYGON. Drawing real interior planes would mean
// clipping a solid against six half-spaces per sample, and none of it would
// survive five taps. So the crystal is built the other way round: six axes on a
// slowly turning frame, and every point in the volume belongs to whichever axis
// its own direction is most aligned with. That partition IS the faceting -- the
// boundaries between the six regions are the crystal's edges, and they fall
// where they would on a real cut stone, because "nearest axis" is exactly how a
// convex polyhedron divides the directions around itself.
//
// WHAT MAKES IT CATCH LIGHT is then one dot product: each facet is lit by how
// squarely its own axis faces the key, so as the frame turns, facets come up
// bright one after another and go dark as they roll away. That sequence is the
// species. It needs no animation of its own -- the turning does all of it -- and
// it is why this hero reads as crystalline rather than as a lit blob.
//
// SOFT-EDGED, WHICH THE BRIEF INSISTS ON AND WHICH THE PARTITION DOES NOT GIVE
// FOR FREE. The gap between the best axis and the runner-up is how far inside
// its facet a point is, and near an edge that gap goes to zero -- so the edge is
// available as a smooth field rather than as a discontinuity. It is used twice:
// to crossfade the lighting between neighbouring facets so no boundary is ever
// a step, and to lay a fine bright line along the edges themselves, which is
// what a cut crystal does and what `glimmer` dials.
//
// THE CRYSTAL SITS INSIDE THE GLASS rather than filling it: a shell profile
// keeps it clear of the shell so it reads as a stone suspended in a body rather
// than as the body's own faceting. `depthCrystal` moves it in and out.
//
// LEVEL LIGHTS THE STONE: voice raises the facets' response to the key, so more
// of them are bright at once and the crystal opens up. ACTIVITY TURNS IT: the
// frame's rotation quickens, so facets change over faster -- a busy assistant's
// stone is turning in the light.
//
// RESPONDING SETTLES IT INTO ONE ATTITUDE and drives the turn one way, so the
// tumbling becomes a rotation with a direction.
//
// THE GESTURE, every ten seconds or so: one facet takes far more light than its
// share for a breath, the way a real stone throws a flash as it passes an angle.
//
// SUCCESS: every facet lights at once, which on a faceted body is unmistakably
// an event, and then settles back to the sequence.
//
// SIZE: at 18 pt the axis count drops from six to four -- six facets across a
// thirteen-point bead is a texture, four is a cut stone -- the edge lines switch
// off, and the crystal grows to fill more of the body. What survives is a small
// turning solid catching light on two or three faces.
[[ stitchable ]] half4 mh_geode(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float facetK  = clamp(c0, 0.0, 1.0);   // how sharply cut
    float glimK   = clamp(c1, 0.0, 1.0);   // the edge lines
    float depthK  = clamp(c2, 0.0, 1.0);   // how big the stone is
    float spreadK = clamp(c3, 0.0, 1.0);   // facet hues

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.021 + 0.007 * mh_breath(t, 11.7), 0.0, 1.22);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float4 fl = mh_flourish(t, 19.0, 10.2);

    // The frame the stone is cut on. Tumbling at rest, driven under responding.
    float sp = (1.0 + 0.80 * live.pace + 1.00 * st.drive);
    float ay = mix(mh_drift(t, 0.088 * sp, 0.48, 2.0), t * 0.30 * sp, st.drive * 0.7);
    float ax = mix(0.34 + 0.22 * sin(t * 0.041), 0.30, st.drive * 0.7);

    // Six axes: three orthogonal pairs, tilted off the cardinal directions so
    // the cut never lines up with the frame and looks machined.
    float3 A0 = normalize(float3( 0.94,  0.28,  0.19));
    float3 A1 = normalize(float3(-0.22,  0.91,  0.35));
    float3 A2 = normalize(float3( 0.16, -0.31,  0.94));
    float3 A3 = normalize(float3( 0.61, -0.58,  0.54));
    float3 A4 = normalize(float3(-0.66, -0.42,  0.62));
    float3 A5 = normalize(float3( 0.38,  0.72, -0.58));
    float fifth = 1.0 - smoothstep(0.24, 0.66, small);   // six facets down to four

    float3 keyF = mh_spin(mh_key(t), ay, ax);

    float Rin = (0.62 + 0.16 * depthK) * S * mix(1.0, 1.12, small);
    float sharp = 3.0 + 7.0 * facetK;
    float glimAmt = glimK * (1.0 - small) * (0.55 + 0.55 * live.voice);
    float medAmt = mix(0.052, 0.030, small);

    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        // The stone: a soft solid sitting inside the glass.
        // A SHELL, NOT A BALL, and the reason is a real degeneracy rather than
        // a preference. The facet a point belongs to is decided by its
        // DIRECTION from the centre, and direction is undefined at the centre
        // and changes arbitrarily fast near it -- so every ray passing through
        // the middle of the stone crossed several facets in a few samples and
        // drew a hard radial seam out of the core. Fading the crystal out below
        // 0.38 of its radius removes the degenerate region entirely and leaves a
        // soft glowing heart where the facets used to fight, which is what the
        // inside of a geode looks like anyway.
        float rr = length(p) / max(Rin, 1e-3);
        float stone = (1.0 - smoothstep(0.55, 1.05, rr)) * smoothstep(0.10, 0.38, rr);
        if (stone <= 0.002) {
            float med0 = mh_medium(p, t, 2.0 / S) * medAmt * fade;
            acc.x += med0 * trans * ds;
            trans *= exp(-(2.0 * med0 + MH_EXT) * ds);
            continue;
        }

        float3 n = mh_spin(normalize(p + 1e-5), ay, ax);

        // WHICH FACET, and how far inside it. The runner-up is kept because the
        // gap between first and second IS the distance to the edge.
        float d0 = dot(n, A0), d1 = dot(n, A1), d2 = dot(n, A2);
        float d3 = dot(n, A3), d4 = dot(n, A4), d5 = dot(n, A5) * fifth;
        float best = max(max(max(d0, d1), max(d2, d3)), max(d4, d5));
        float second = -2.0;
        second = max(second, (d0 < best) ? d0 : -2.0);
        second = max(second, (d1 < best) ? d1 : -2.0);
        second = max(second, (d2 < best) ? d2 : -2.0);
        second = max(second, (d3 < best) ? d3 : -2.0);
        second = max(second, (d4 < best) ? d4 : -2.0);
        second = max(second, (d5 < best) ? d5 : -2.0);

        // Which axis won, as a light and a hue. Written as a weighted blend
        // rather than a branch so the crossover between neighbouring facets is
        // a crossfade: the brief says soft-edged, and a hard pick here would put
        // a visible crease down every boundary in the stone.
        float soft = 0.055 + 0.075 * (1.0 - facetK);
        float w0 = exp((d0 - best) / soft), w1 = exp((d1 - best) / soft);
        float w2 = exp((d2 - best) / soft), w3 = exp((d3 - best) / soft);
        float w4 = exp((d4 - best) / soft), w5 = exp((d5 - best) / soft) * fifth;
        float wsum = w0 + w1 + w2 + w3 + w4 + w5 + 1e-5;

        float3 fn = normalize((A0 * w0 + A1 * w1 + A2 * w2
                             + A3 * w3 + A4 * w4 + A5 * w5) / wsum + 1e-5);

        // THE CATCH. Each facet is lit by how squarely it faces the key -- and
        // the comparison happens in the STONE'S frame, with the key rotated into
        // it, rather than the other way round. Rotations preserve dot products,
        // so the answer is identical, and this way there is no inverse rotation
        // to write: the axes are already in the cut frame and the key only has
        // to be carried across once, outside the loop.
        float face = pow(clamp(dot(fn, keyF), 0.0, 1.0), sharp * 0.5);
        float lit = 0.16 + 1.05 * face * (1.0 + 0.75 * live.voice);

        // THE GESTURE: one facet takes far more than its share for a breath.
        if (fl.x > 0.002) {
            float pick = floor(fl.z * 5.999);
            float mine = (pick < 0.5) ? w0 : (pick < 1.5) ? w1 : (pick < 2.5) ? w2
                       : (pick < 3.5) ? w3 : (pick < 4.5) ? w4 : w5;
            lit += fl.x * 1.60 * (mine / wsum);
        }
        if (st.complete > 0.001) lit += st.complete * 0.85;

        // THE EDGES. The gap between the winner and the runner-up, read as a
        // thin bright line along every boundary in the stone.
        float edge = 0.0;
        if (glimAmt > 0.002) {
            float gap = (best - second) / soft;
            edge = glimAmt * 0.55 * exp(-gap * gap * 0.35);
        }

        float e = (stone * lit * 0.42 + edge * stone) * fade;
        float med = mh_medium(p, t, 2.0 / S) * medAmt * fade;
        e += med;

        acc.x += e * trans * ds;
        // Facets take hue by which axis won, so neighbouring faces of the stone
        // are neighbouring hues and the crystal has play of colour in it.
        float hk = (w0 * -1.0 + w1 * -0.4 + w2 * 0.15 + w3 * 0.55 + w4 * 1.0 + w5 * 0.3) / wsum;
        acc.y += (stone * lit * 0.42) * hk * fade * trans * ds;
        trans *= exp(-(2.40 * e + MH_EXT) * ds);
    }

    float interior = acc.x * 4.40 * b.m * mh_transmit(b.fres) * (1.0 + 0.22 * st.settled);
    float hue = (acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD;

    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.80 + 0.35 * live.voice, 0.72, 0.14);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(interior + sf.rim, sf.spec, sf.glow, hueMix,
                      uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 16. Sol

// SOL. A miniature sun: soft prominences lifting and falling inside the glass.
//
// THE KNEE DOES THE HEAVY WORK HERE, and this is the one species designed around
// it rather than merely protected by it. A star is the only subject in the
// collection whose honest dynamic range is enormous: the photosphere is orders
// of magnitude above the corona, which is orders above the prominences. Fed
// straight to the rail that renders as a flat white disc with some dim fuzz
// round it -- which is exactly what a clamp would give and exactly what the
// first cut of droplet's success looked like. mh_knee compresses the overshoot
// asymptotically instead, so a core running at four times the rail's top still
// has structure in it and the prominences an eighth as bright are still
// separable. Everything below is built assuming that compression exists; at a
// clamp this hero would have no picture.
//
// THREE LAYERS, AND THEY ARE DIFFERENT KINDS OF THING. The PHOTOSPHERE is a
// solid body with a soft limb, granulated by a fine field that `simmer` dials --
// it is the only opaque object any hero puts in the glass, and the interior
// march's transmittance makes it genuinely occlude what is behind it. The CORONA
// is a wide soft falloff off that limb, which is what gives the sun its size. The
// PROMINENCES are tongues: soft plumes rooted on the surface at drifting
// directions, each lifting and falling on its own long cycle so the sun's
// silhouette is always changing without ever pulsing.
//
// A PROMINENCE IS A DIRECTION PLUS A HEIGHT. The angular term is how close the
// sample's own direction is to the plume's, the radial term is a soft arch from
// the surface out to the plume's current height and back, and the product is a
// tongue of light standing off the limb. Four of them on incommensurate periods
// -- 13, 17, 21 and 25 seconds -- so they are never all up or all down and the
// star never looks like it is breathing.
//
// LEVEL LIFTS THEM: voice raises every plume's height and brightens the core, so
// speaking makes the sun visibly more active. That is the most literal reading
// of `level` in the collection and on this subject it is the right one.
// ACTIVITY QUICKENS THE SIMMER, the fine granulation crawling across the
// photosphere, which is the small motion a working star should have.
//
// RESPONDING DRIVES ONE PROMINENCE OUT: the plumes bias toward a single heading
// and the leading one reaches half again its usual height. A star with a flare
// pointing somewhere reads as intent.
//
// THE GESTURE, every twelve seconds or so: one plume arches much higher than the
// rest and settles back.
//
// SUCCESS: every prominence lifts together and the corona flares, which is the
// only moment the star is symmetric, then it settles brighter.
//
// SIZE: at 18 pt two of the four plumes crossfade away, the survivors are half
// again as wide, the granulation switches off, and the core grows to fill more
// of the body. What survives is a small bright sun with one or two soft tongues
// standing off it.
[[ stitchable ]] half4 mh_sol(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float coronaK = clamp(c0, 0.0, 1.0);   // how far the corona reaches
    float promK   = clamp(c1, 0.0, 1.0);   // how high the tongues stand
    float simmerK = clamp(c2, 0.0, 1.0);   // the granulation
    float spreadK = clamp(c3, 0.0, 1.0);

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.022 + 0.008 * mh_breath(t, 12.9), 0.0, 1.24);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float4 fl = mh_flourish(t, 23.0, 12.4);

    float Rs = (0.30 + 0.10 * coronaK) * S * mix(1.0, 1.45, small);
    // The corona came down by a third from the first cut. It is what gives the
    // star its size, but at the original reach it filled every angle the
    // prominences stand in and they had nothing dark to stand against -- four
    // tongues were being drawn and none of them could be seen.
    float corona = (0.17 + 0.16 * coronaK) * S * (1.0 + 0.25 * live.voice);
    float coreBright = (1.05 + 0.45 * coronaK) * (1.0 + 0.55 * live.voice)
                     * (1.0 + 0.55 * st.complete);

    float simGate = mh_aa(6.2831853 * 8.5 / (MH_R * S), size, pixelScale) * (1.0 - small);
    float simAmt = simGate * (0.35 + 0.65 * simmerK) * (0.55 + 0.65 * live.pace);
    float simRate = t * (0.35 + 0.75 * live.pace);

    float pairB = 1.0 - smoothstep(0.28, 0.70, small);
    float promW = (0.26 + 0.12 * promK) * mix(1.0, 1.55, small);
    float promH = (0.55 + 0.60 * promK) * (1.0 + 0.55 * live.voice) * S;

    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);

    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;

        float r = length(p);
        float3 n = normalize(p + 1e-5);

        // THE PHOTOSPHERE. A solid body with a soft limb -- the only opaque
        // thing in the collection -- granulated by a fine field.
        float core = 1.0 - smoothstep(Rs * 0.78, Rs * 1.10, r);
        if (simAmt > 0.002) {
            // READ IN THE VOLUME, NOT ON THE DIRECTION. Sampling granulation at
            // normalize(p) is the same degeneracy geode's facets hit: direction
            // is undefined at the centre and spins arbitrarily fast near it, so
            // the photosphere grew a hard radial starburst out of its own core.
            // A plain 3D field has no such point, and on a body this size the
            // difference in what it draws on the LIMB -- where granulation is
            // actually read -- is nothing.
            core *= 1.0 + simAmt * 0.40 * mh_noise3(p * (8.5 / S) + float3(0.0, 0.0, simRate));
        }

        // THE CORONA: a wide soft falloff off the limb, which is the sun's size.
        float cor = exp(-max(r - Rs, 0.0) / max(corona, 1e-3)) * (1.0 - core * 0.55);

        // THE PROMINENCES. Four tongues, each a direction and a height, on
        // periods that never come into step.
        float prom = 0.0;
        for (int k = 0; k < 4; k++) {
            float wk = (k < 2) ? 1.0 : pairB;
            if (wk < 0.002) continue;
            float fk = float(k);
            float per = 13.0 + 4.0 * fk;
            float ph = fk * 2.13;
            // Lift and fall: sin-squared, so it leaves the surface and returns
            // to it with flat ends and never snaps.
            float sn = sin(6.2831853 * t / per + ph);
            float lift = sn * sn;
            if (fl.x > 0.002 && k == int(fl.z * 3.999)) lift = max(lift, fl.x);
            lift = mix(lift, 1.0, st.complete * 0.85);

            // The plume's heading, drifting slowly; under drive they all bias
            // toward one direction and the leading one reaches higher.
            float a1 = t * (0.048 + 0.011 * fk) + fk * 1.9;
            float a2 = t * (0.037 + 0.009 * fk) + fk * 3.1;
            float3 dir = normalize(float3(cos(a1) * cos(a2), sin(a2), sin(a1) * cos(a2)));
            dir = normalize(mix(dir, normalize(float3(0.86, -0.32, 0.39)), st.drive * 0.70));
            float hk = promH * lift * (1.0 + 0.55 * st.drive * (k == 0 ? 1.0 : 0.0));

            float ang = clamp(dot(n, dir), -1.0, 1.0);
            float lat = (1.0 - ang) / max(promW * promW, 1e-4);
            // The arch: up off the surface to hk and back down.
            float hgt = (r - Rs) / max(hk, 1e-3);
            float arch = exp(-lat) * exp(-hgt * hgt * 1.35) * step(0.0, r - Rs * 0.85);
            prom += arch * wk * lift;
        }

        float e = (core * coreBright + cor * 0.42 + prom * 1.65) * fade;

        acc.x += e * trans * ds;
        // Hue runs outward: the core on the anchor, the corona and the tongues
        // walking to the neighbour, which is what a star's own colour does with
        // depth through its atmosphere.
        acc.y += (cor * 0.42 + prom * 1.65) * fade * trans * ds;
        // The photosphere is OPAQUE. This is the coefficient that makes it so,
        // and it is what puts a real silhouette between the near tongues and the
        // far ones.
        trans *= exp(-(5.20 * core + 1.30 * (cor + prom) + MH_EXT) * ds);
    }

    float interior = acc.x * 2.30 * b.m * mh_transmit(b.fres) * (1.0 + 0.20 * st.settled);
    float hue = (acc.x > 1e-4 ? acc.y / acc.x : 0.0) * spreadK * MH_SPREAD;

    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.72 + 0.35 * live.voice, 0.58, 0.16);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * (interior + sf.rim * 0.7) / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(interior + sf.rim, sf.spec, sf.glow, hueMix,
                      uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 17. Abyss

// ABYSS. Deep-sea dark glass: rare glows passing through, mostly night.
//
// THE PATIENCE PIECE, and it is the only hero in the collection whose default
// state is genuinely almost nothing happening. Still is quiet; this one is dark.
// The distinction matters: still's rim and catchlight are the figure and they
// are there every frame, where here the rim is a thin cold line holding a
// silhouette and the events are the species -- and the events are RARE. At the
// default `rarity` a creature passes roughly every twenty seconds, and between
// them there is a dark bead with an edge. Nothing else in this collection asks
// the viewer to wait, and a set of eighteen presences needs one that does.
//
// RARITY IS THE SLOT LENGTH and it runs the intuitive way: high is rarer. Three
// lanes on long, independently jittered clocks, so the gaps between passes are
// never equal and two creatures overlap only occasionally -- which is exactly
// when the frame is worth catching.
//
// A CREATURE IS A PASSAGE, NOT AN APPEARANCE. It enters on one side of the
// volume and leaves by the other over the whole life of its gesture, on a line
// hashed per pass, so what the eye sees is something crossing rather than
// something switching on in place. It is solved at the ray's closest approach --
// the same closed form comet's head and droplet's heart use -- so it is round
// and stable, and most of its light is in the scatter, because a glow in deep
// water is mostly the water it lights.
//
// LEVEL BRINGS THEM UP. Voice brightens whatever is passing and, more usefully,
// shortens the clocks: speak to it and the abyss becomes populated. That is the
// one reading of `level` that suits a species whose subject is scarcity --
// brightness alone would say nothing about a body that is dark on purpose.
// ACTIVITY QUICKENS THEIR DRIFT, so a busy assistant's creatures cross faster.
//
// RESPONDING TURNS THEM INTO A PROCESSION: the paths align on one heading and
// the clocks shorten hard, so rare passages become a steady stream in one
// direction. It is the largest behavioural change any state makes to any hero
// here, and it should be: this is the species with the most room to change.
//
// SUCCESS: the whole volume lights once, briefly, the way a deep-sea bloom does,
// and falls back to night a little less dark than before.
//
// SIZE: at 18 pt one lane crossfades away and the survivors grow by 80 per cent
// and brighten, because a small dim glow inside a small dark bead is invisible
// rather than restrained. The clocks also shorten by a third: at a glance you
// should see the species do its one thing, not wait through its silence.
[[ stitchable ]] half4 mh_abyss(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float creatureK = clamp(c0, 0.0, 1.0);   // how many, how bright
    float rarityK   = clamp(c1, 0.0, 1.0);   // high is rarer
    float driftK    = clamp(c2, 0.0, 1.0);   // how fast they cross
    float spreadK   = clamp(c3, 0.0, 1.0);

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.019 + 0.006 * mh_breath(t, 14.1), 0.0, 1.14);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    // THE CLOCKS. Rarity sets the slot; voice and drive shorten it hard, and the
    // small mounts shorten it again so the species shows itself at a glance.
    float base = mix(9.0, 26.0, rarityK)
               / (1.0 + 0.55 * live.voice + 0.35 * live.pace + 1.60 * st.drive);
    base *= mix(1.0, 0.66, small);
    float4 c0f = mh_flourish(t, 31.0, base);
    float4 c1f = mh_flourish(t, 37.0, base * 1.37);
    float4 c2f = mh_flourish(t, 41.0, base * 1.81);
    float thirdC = 1.0 - smoothstep(0.30, 0.72, small);

    float rad = (0.155 + 0.075 * creatureK) * S * mix(1.0, 1.80, small);
    float bright = (0.85 + 0.75 * creatureK) * (1.0 + 0.95 * live.voice)
                 * mix(1.0, 1.45, small);
    float reach = 0.62 + 0.30 * driftK;

    float glowE = 0.0, glowH = 0.0;
    for (int k = 0; k < 3; k++) {
        float4 f = (k == 0) ? c0f : (k == 1) ? c1f : c2f;
        float wk = (k < 2) ? 1.0 : thirdC;
        if (f.x <= 0.002 || wk < 0.002) continue;
        float fk = float(k);

        // THE PASSAGE. A line hashed per pass; under drive they all take one
        // heading and the abyss becomes a current.
        float ga = f.z * 6.2831853 + fk * 1.7;
        float3 dir = normalize(mix(float3(cos(ga), 0.40 * sin(ga * 1.6 + fk), sin(ga * 0.8 + 1.3)),
                                   float3(0.90, -0.22, 0.37), st.drive * 0.80));
        float3 side = normalize(cross(dir, float3(0.08, 1.0, 0.14)));
        float3 gp = side * (0.42 * (f.z * 2.0 - 1.0) * (1.0 - 0.7 * st.drive))
                  + dir * mix(-reach, reach, smoothstep(0.0, 1.0, f.y));

        float3 to = gp - b.P;
        float s = dot(to, rd);
        if (s <= 0.0 || s >= L) continue;
        float arg = max(dot(to, to) - s * s, 0.0) / max(rad * rad, 1e-6);
        float vis = mh_inside(b.P + rd * s) * exp(-MH_EXT * s);
        // Mostly scatter: a glow in deep water is the water it lights.
        float e = (exp(-arg) * 0.45 + mh_scatter(arg, 0.52)) * vis * f.x * bright * wk;

        glowE += e;
        glowH += e * ((fk - 1.0));
    }

    // NIGHT. The floor is a third of what the quietest luminous hero carries:
    // enough that the far wall exists, not enough to be a colour.
    float medAmt = mix(0.022, 0.014, small) * (1.0 + 0.60 * live.voice);
    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);
    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;
        float e = mh_medium(p, t, 1.9 / S) * medAmt;
        if (st.complete > 0.001) {
            float sr = (length(p) - mix(0.02, 1.0, st.sweep)) / 0.26;
            e += st.complete * 0.42 * exp(-sr * sr);
        }
        acc.x += e * trans * ds;
        trans *= exp(-(2.00 * e + MH_EXT) * ds);
    }

    float interior = (acc.x * 3.20 + glowE) * b.m * mh_transmit(b.fres)
                   * (1.0 + 0.26 * st.settled);
    float hue = (glowE > 1e-5 ? glowH / glowE : 0.0) * spreadK * MH_SPREAD;

    // A COLD THIN EDGE. The rim is the only thing here every frame, so it holds
    // the silhouette on its own -- but it runs lower than still's, because this
    // body is meant to read as dark rather than as quiet.
    // THE CATCHLIGHT COMES DOWN TO A THIRD of what the luminous heroes wear.
    // At 0.62 there was a bright point sitting on the shell in every single
    // frame, including the long dark stretches this species exists for -- and a
    // permanent highlight on a body whose subject is rarity does not read as
    // glass, it reads as something stuck. What is left is enough to say the
    // surface is polished and not enough to be an event.
    // AND THE RIM GOES UP, not down. It is the only thing in the frame during
    // the long dark stretches, and a rim term peaks around a third of its
    // coefficient once the fresnel and the membership have taken their share --
    // so at 0.92 the silhouette was genuinely almost invisible and the species
    // read as an empty cell rather than as a dark one. 1.70 is the highest in
    // the collection, which is right: this is the hero with the least else.
    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 1.70 + 0.55 * live.voice, 0.38, 0.11);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * glowE / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(interior + sf.rim, sf.spec, sf.glow, hueMix,
                      uv, pal, glow, inkColor, position, pixelScale);
}

// MARK: - 18. Chorus

// CHORUS. Many faint lights breathing loosely, falling into alignment.
//
// THE ONE HERO LICENSED A RHYTHM, and the licence is narrow. The family's verbs
// are FLOW and SETTLE, and breathing luminance is banned as a default motif
// precisely because it is the first thing everyone reaches for. The carve-out in
// the house rules is for a species whose concept literally IS a rhythm, and an
// ensemble breathing is that: the pulse is not decoration on the idea, it is the
// idea, and the thing the species is actually about is not the breathing at all
// but the PHASE RELATIONSHIP between the breaths.
//
// SO THE DESIGN IS SYNC, NOT PULSE. At rest the voices are scattered across the
// cycle -- `sync` at zero spreads them over a full period -- and what the eye
// reads is a loose, uncountable shimmer with no beat in it, because nothing ever
// coincides. As sync rises they gather, and at one they breathe as a single
// body. RESPONDING drives sync most of the way to one, so an assistant that is
// answering visibly pulls its ensemble together. That transition from many
// rhythms to one is the whole species, and it is why the rhythm had to be
// allowed: you cannot show alignment without something to align.
//
// KEPT GENTLE, which is the other half of the licence. The depth of the breath
// is capped so no voice ever goes out entirely -- the floor is a third -- and
// the period is long, eight seconds and up. What that produces even at full
// alignment is a slow swell across a field of small lights, not a blink.
//
// SEVEN VOICES ON A FIBONACCI SHELL, so they are evenly spread over the sphere
// without any two ever lining up into a row or a ring. Each drifts a little on
// its own slow path, and each is solved at the ray's closest approach, so seven
// compact lights cost fourteen dot products and are perfectly round.
//
// LEVEL PICKS OUT THE NEAREST. Voice does not simply brighten the ensemble: it
// weights each voice by how near the front of the glass it is, so speaking makes
// the closest lights bloom and leaves the far ones where they were. An ensemble
// where the front row answers is a much better picture of being listened to than
// one where everybody gets louder.
//
// ACTIVITY QUICKENS THE BREATHING a little, and only a little: this is the hero
// where a fast rhythm would be worst.
//
// THE GESTURE, every eleven seconds or so: one voice swells well past the rest
// and subsides, the way a single singer lifts out of a choir.
//
// SUCCESS: every voice reaches full together, which after a hero built entirely
// on their not coinciding is the most legible arrival in the collection.
//
// SIZE: at 18 pt the ensemble drops from seven voices to three and they grow by
// 70 per cent, because seven faint lights in a thirteen-point bead is a texture
// and three is a group. Their breath also deepens, since with fewer voices there
// is less overlap to carry the motion.
[[ stitchable ]] half4 mh_chorus(
    float2 position, half4 currentColor, float2 size, float time, float pixelScale,
    half4 inkColor, half4 toneColor,
    float hueShift, float formScale, float speed, float depth, float glow,
    float c0, float c1, float c2, float c3, float epoch,
    float stateIndex, float stateTau, float level, float activity,
    float2 tilt, half4 tone2
) {
    float2 uv = (position - 0.5 * size) / max(min(size.x, size.y), 1.0);
    float S = max(formScale, 0.10);
    float t = time * max(speed, 0.0);

    float voicesK = clamp(c0, 0.0, 1.0);   // how many sing
    float syncK   = clamp(c1, 0.0, 1.0);   // how together they are at rest
    float depthK  = clamp(c2, 0.0, 1.0);   // how deep the breath
    float spreadK = clamp(c3, 0.0, 1.0);

    MHState st = mh_state(stateIndex, stateTau);
    MHLive live = mh_live(level, activity, stateIndex);
    float small = mh_small(size);
    float px = 1.0 / (max(min(size.x, size.y), 1.0) * max(pixelScale, 1.0) * MH_R);

    MHShape sh = mh_shape(0.021 + 0.008 * mh_breath(t, 15.6), 0.0, 1.20);
    MHBody b = mh_body(uv, t, px, sh);

    float3 V = float3(0.0, 0.0, -1.0);
    float3 rd = mh_look(V, b.N, tilt);
    float L = mh_exit(b.P, rd);

    float4 fl = mh_flourish(t, 29.0, 11.1);

    // ALIGNMENT. At rest the knob sets it; responding pulls it most of the way
    // to one, which is the species' whole gesture.
    float sync = clamp(syncK * 0.75 + 0.85 * st.drive + 0.55 * st.complete, 0.0, 1.0);
    float per = 8.4 - 2.2 * (live.pace * 0.6);
    float breathe = (0.30 + 0.45 * depthK) * mix(1.0, 1.35, small);

    // Voices count down at the small mounts.
    float mid = 1.0 - smoothstep(0.26, 0.62, small);
    float far = 1.0 - smoothstep(0.10, 0.42, small);

    // Small enough to stay separate on a shell this size: at 0.14 against a
    // spacing of about 0.35 the seven ran together into one lobed mass and the
    // ensemble stopped being countable, which is the one thing an ensemble has
    // to be.
    float rad = (0.082 + 0.038 * voicesK) * S * mix(1.0, 1.75, small);
    float bright = (0.70 + 0.55 * voicesK);
    float turn = mh_drift(t, 0.048, 0.45, 2.0);

    float voiceE = 0.0, voiceH = 0.0;

    for (int k = 0; k < 7; k++) {
        float fk = float(k);
        float wk = (k < 3) ? 1.0 : ((k < 5) ? mid : far);
        if (wk < 0.002) continue;

        // A FIBONACCI SHELL: evenly spread, never in a row or a ring.
        float zc = 1.0 - 2.0 * (fk + 0.5) / 7.0;
        float rc = sqrt(max(1.0 - zc * zc, 0.0));
        float ang = fk * 2.39996323 + turn;
        float3 dirk = float3(rc * cos(ang), zc, rc * sin(ang));
        // Each drifts a little on its own slow path, so the shell is never rigid.
        float3 c = dirk * (0.54 + 0.09 * sin(t * (0.061 + 0.009 * fk) + fk * 2.2))
                 + float3(0.05 * sin(t * 0.043 + fk), 0.05 * sin(t * 0.037 + fk * 1.7), 0.0);
        c *= S;

        // THE BREATH. The phase spread is what sync closes: at zero the seven
        // are scattered over the whole cycle, at one they are on the same beat.
        // Floored at a third, so no voice ever goes out and the ensemble never
        // blinks.
        float phase = mix(fk * 0.897, 0.0, sync) * 6.2831853;
        float sn = sin(6.2831853 * t / per + phase);
        float life = 1.0 - breathe + breathe * sn * sn;
        if (fl.x > 0.002 && k == int(fl.z * 6.999)) life += fl.x * 0.85;
        life = mix(life, 1.0 + 0.45 * st.complete, st.complete * 0.9);

        float3 to = c - b.P;
        float s = dot(to, rd);
        if (s <= 0.0 || s >= L) continue;
        float arg = max(dot(to, to) - s * s, 0.0) / max(rad * rad, 1e-6);
        float vis = mh_inside(b.P + rd * s) * exp(-MH_EXT * s);

        // LEVEL PICKS OUT THE NEAREST. Voice is weighted by how far forward the
        // voice sits, so the front of the ensemble answers and the back does not.
        float front = 0.5 + 0.5 * clamp(c.z, -1.0, 1.0);
        float lift = 1.0 + live.voice * (0.25 + 1.15 * front);

        float e = (exp(-arg) * 0.60 + mh_scatter(arg, 0.42)) * vis * life * lift * bright * wk;
        voiceE += e;
        voiceH += e * ((fk - 3.0) / 3.0);
    }

    float medAmt = mix(0.048, 0.028, small);
    float2 acc = float2(0.0);
    float trans = 1.0;
    float ds = L / float(MH_TAPS);
    for (int i = 0; i < MH_TAPS; i++) {
        float3 p = b.P + rd * ((float(i) + 0.5) * ds);
        float fade = mh_inside(p);
        if (fade <= 0.001) continue;
        float e = mh_medium(p, t, 2.1 / S) * medAmt;
        acc.x += e * trans * ds;
        trans *= exp(-(2.00 * e + MH_EXT) * ds);
    }

    float interior = (acc.x * 3.30 + voiceE) * b.m * mh_transmit(b.fres)
                   * (1.0 + 0.22 * st.settled);
    float hue = (voiceE > 1e-5 ? voiceH / voiceE : 0.0) * spreadK * MH_SPREAD;

    MHSurface sf = mh_surface(b, t, small, inkColor, tilt, 0.80 + 0.35 * live.voice, 0.50, 0.14);

    float e = interior + sf.rim + sf.spec + sf.glow;
    float hueMix = hue * voiceE / max(e, 1e-4);

    MHPalette pal = mh_palette(inkColor, toneColor, tone2, hueShift, depth);
    return mh_present(interior + sf.rim, sf.spec, sf.glow, hueMix,
                      uv, pal, glow, inkColor, position, pixelScale);
}
