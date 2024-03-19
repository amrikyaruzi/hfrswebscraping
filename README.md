# Web Scraping Project - Tanzania HFRS

### Introduction

This is a Julia web scraping project with instructions on how to scrape data from the Tanzania Ministry of Health's Health Facility Registration System ([HFRS](https://hfrs.moh.go.tz/)) portal.

The Health Facility Registration System is a list of all facilities registered (whether operation or not) to operate in Tanzania mainland. Data specifically scraped here comes from the private and public health facilities lists.

### Web Scraping packages used

> [TidierVest.jl](https://github.com/TidierOrg/TidierVest.jl), a Julia implementation of the rvest R package is used in the "Julia - Webscraping - TidierVest.jl" code and the [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl), [Cascadia.jl](https://github.com/Algocircle/Cascadia.jl), and [Gumbo.jl](https://github.com/JuliaWeb/Gumbo.jl) pakages are used for scraping in the "Julia - Webscraping.jl" code. Other packages were also used for data wrangling.


### Downloading & Reproducing

To (locally) reproduce this project, do the following:

1. Download this code base.
3. Open a Julia console and do the following:

```julia-repl
using Pkg
Pkg.activate("path/to/this/project")
Pkg.instantiate()
```

This should install all necessary packages for you to be able to run the scripts.
