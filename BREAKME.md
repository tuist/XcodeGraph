# BREAKME

This document lists breaking changes to introduce in the next major version of the project.
Every change must include what needs to be changed, and the rationale behind it. 

## Changes

## Drop `TargetMetadata.init`

We added the `TargetMetadata.metadata` API that gives us more flexibility and makes the instantiation of metadata more idiomatic. Therefore, we should remove `TargetMetadata.init`.