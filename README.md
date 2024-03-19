# Web Scraping Project - Tanzania HFRS

### Introduction

This is a Julia web scraping project with instructions on how to scrape data from the Tanzania Ministry of Health's Health Facility Registration System (HFRS) portal (https://hfrs.moh.go.tz/).

The Health Facility Registration System is a list of all facilities registered (whether operation or not) to operate in Tanzania mainland. Data specifically scraped here pertains to the private and public health facilities lists.

### Scraping packages used

TidierVest.jl, a Julia implementation of the rvest R package is used in the Julia - Webscraping - TidierVest.jl code and the HTTP.jl, Cascadia.jl, and Gumbo.jl pakages are used for scraping in the Julia - Webscraping.jl code. Other packages were also used for data wrangling.
