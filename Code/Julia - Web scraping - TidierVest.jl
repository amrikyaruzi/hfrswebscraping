read(run(`powershell cls`), String)

using HTTP, JSON
using DataFrames
using Tidier
using TidierVest
using Chain
using BenchmarkTools
using Printf
using CSV
using XLSX


private_start_url = "https://hfrs.moh.go.tz/web/index.php?r=portal%2Fquick-search&filters=priv&page=1"
public_start_url = "https://hfrs.moh.go.tz/web/index.php?r=portal%2Fquick-search&filters=publ&page=1"


function last_page(start_page)
    @chain start_page begin
      read_html(_)
      html_elements(_, ".page-item.last")
      html_elements(_, ".page-link")
      html_attrs(_, "href")
      match(r"\d*$", _[1]).match
      parse(Int, _)
    end
  end


private_last_page_number = last_page(private_start_url)
public_last_page_number = last_page(public_start_url)


public_base_url = "https://hfrs.moh.go.tz/web/index.php?r=portal%2Fquick-search&filters=publ&page="
private_base_url = "https://hfrs.moh.go.tz/web/index.php?r=portal%2Fquick-search&filters=priv&page="


function generate_all_links(base_url::String, last_page_number::Int)
    links = map(1:last_page_number) do x
        @sprintf("%s%d", base_url, x)
    end
    return links
end


all_links_private = generate_all_links(private_base_url, private_last_page_number)
all_links_public = generate_all_links(public_base_url, public_last_page_number)


all_links = append!(all_links_private, all_links_public)


function get_data(link)
    @chain link begin
      read_html(_)
      html_elements(_, [".kv-grid-table", ".table", ".table-bordered",".table-striped", ".kv-table-wrap"])
      html_table(_)
    end
  end



number_of_tasks = length(all_links[1:50])
results = Vector{DataFrame}(undef, number_of_tasks)



@time asyncmap(all_links[1:50]; ntasks = 100) do link
    data = get_data(link)
    println("$link scraped successfully!")
    return data
end |> (x -> results .= x)



# Merge the results into a single DataFrame
facilities_data = vcat(results...)

# Merge the results and save them in a DataFrame
facilities_data = DataFrame(facilities_data)



for col in names(facilities_data)
    println("Column: $col, Type: $(eltype(facilities_data[!, col]))")
end



XLSX.writetable("./Output/HFRS Julia 15 Mar 24_.xlsx", collect(eachcol(facilities_data)),
                names(facilities_data), overwrite = true)

