---
# DESIGN.md - Google DESIGN.md format (https://github.com/google-labs-code/design.md, version alpha).
# Tokens here are the normative values; the prose below says why and how to apply them.
# Check after every edit: designmd lint DESIGN.md   (0 errors; read the warnings)
version: alpha
name: <Product name>
description: <One sentence on the look and feel. Replace every placeholder before the first UI is built.>
colors:
  primary: "#1A1C1E"
  on-primary: "#FFFFFF"
  secondary: "#5B6168"
  on-secondary: "#FFFFFF"
  surface: "#F7F5F2"
  on-surface: "#1A1C1E"
  error: "#B3261E"
  on-error: "#FFFFFF"
typography:
  headline-lg:
    fontFamily: <Display family>
    fontSize: 32px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: -0.01em
  headline-md:
    fontFamily: <Display family>
    fontSize: 24px
    fontWeight: 600
    lineHeight: 1.25
  body-md:
    fontFamily: <Text family>
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.6
  label-md:
    fontFamily: <Text family>
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.4
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
rounded:
  sm: 4px
  md: 8px
  full: 9999px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-md}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
  button-secondary:
    backgroundColor: "{colors.secondary}"
    textColor: "{colors.on-secondary}"
    typography: "{typography.label-md}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg}"
  banner-error:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-error}"
    rounded: "{rounded.sm}"
    padding: "{spacing.sm}"
---

# <Product name> design system

<!-- Sections stay in this order (the linter checks it). Prose may be written in Japanese. Delete the guidance
     comments as you fill each section; keep a section even when short, or list it under `omitted` above. -->

## Overview

<!-- Who the product is for, what it should feel like (dense or spacious, playful or sober), and the one or two
     references the visual identity draws on. This is the fallback context for any decision no token covers. -->

## Colors

<!-- One line per palette role with its reason, e.g.
     - Primary (#1A1C1E): ink for headlines and primary actions; carries the brand's seriousness.
     - Surface (#F7F5F2): warm off-white page ground; pure white is reserved for cards.
     Keep hex values in sync with the tokens above; the tokens win when they differ. -->

## Typography

<!-- The families, why they were chosen, and the role of each level (headline / body / label). Note line-length
     limits and any platform substitutions (system fonts on native). -->

## Layout

<!-- Grid or container model, the spacing scale in use (tokens above), breakpoints, and safe areas on native. -->

## Elevation & Depth

<!-- How hierarchy is conveyed: tonal layers, borders, or shadows (with spread / blur / color when used). -->

## Shapes

<!-- Corner radius language and where each level applies. -->

## Components

<!-- Per component: variants, states (hover, pressed, disabled, focus), sizing. Tokens above hold the values. -->

## Do's and Don'ts

<!-- Guardrails that the tokens cannot express, e.g.
     - Do use primary for at most one action per screen.
     - Don't set text below 4.5:1 contrast on any surface.
     - Don't mix rounded.sm and rounded.md in one view. -->
