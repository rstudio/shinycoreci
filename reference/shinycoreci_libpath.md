# Shinyverse libpath

Methods to get and reset the shinyverse `libpath`.

## Usage

``` r
shinycoreci_libpath()

shinycoreci_clean_libpaths()
```

## Functions

- `shinycoreci_libpath()`: Library path that will persist across
  installations. But will have a different path for different R versions

- `shinycoreci_clean_libpaths()`: Removes the cached R library
