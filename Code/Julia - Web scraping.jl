read(run(`powershell cls`), String)

using HTTP, Gumbo, Cascadia
using DataFrames
using Tidier
using Chain
using CSV
using XLSX


private_start_url = "https://hfrs.moh.go.tz/web/index.php?r=portal%2Fquick-search&filters=priv&page=1"
public_start_url = "https://hfrs.moh.go.tz/web/index.php?r=portal%2Fquick-search&filters=publ&page=1"


function last_page(start_page)
  response = HTTP.get(start_page)
  html = parsehtml(String(response.body))
  last_page_path = eachmatch(Selector(".page-item.last .page-link"), html.root)[1].attributes["href"]
  parse(Int, match(r"\d*$", last_page_path).match)
end



private_last_page_number = last_page(private_start_url)
public_last_page_number = last_page(public_start_url)


public_base_url = "https://hfrs.moh.go.tz/web/index.php?r=portal%2Fquick-search&filters=publ&page="
private_base_url = "https://hfrs.moh.go.tz/web/index.php?r=portal%2Fquick-search&filters=priv&page="



function generate_all_links(base_url::String, last_page_number::Int)
    links = map(1:last_page_number) do x
        string(base_url, x)
    end
    return links
end



all_links_private = generate_all_links(private_base_url, private_last_page_number)
all_links_public = generate_all_links(public_base_url, public_last_page_number)

all_links = append!(all_links_private, all_links_public)


# Getting table headers

function get_table_headers()
  response = HTTP.get(all_links[1])
  html = parsehtml(String(response.body))
  table_html = eachmatch(Selector(".kv-grid-table.table.table-bordered.table-striped.kv-table-wrap"), html.root)[1]

  headers = Vector()

  for th in eachmatch(Selector("th a"), table_html)
    println(nodeText(th))
    push!(headers, nodeText(th))
  end
end

get_table_headers()

# Getting table values

function get_table_data(link)
  
  response = HTTP.get(link)
  html = parsehtml(String(response.body))
  table_html = eachmatch(Selector(".kv-grid-table.table.table-bordered.table-striped.kv-table-wrap"), html.root)[1]

  table_data = DataFrame()

  for tbody in eachmatch(Selector("tbody"), table_html)
    for tr in eachmatch(Selector("tr"), tbody)
      facility_id = nodeText(tr[1])
      facility_code = nodeText(tr[2])
      facility_name = nodeText(tr[3])
      facility_type = nodeText(tr[4])
      region = nodeText(tr[5])
      council = nodeText(tr[6])
      ownership_category = nodeText(tr[7])
      ownership_authority = nodeText(tr[8])
      operating_status = nodeText(tr[9])
  
      """"row_data = DataFrame(facility_id = facility_id, facility_code = facility_code, facility_name = facility_name,
      facility_type = facility_type, region = region, council = council, ownership_category = ownership_category,
      ownership_authority = ownership_authority, operating_status = operating_status)"""

      row_data = DataFrame(facility_id = facility_id, facility_code = facility_code,
      facility_name = facility_name, facility_type = facility_type, region = region,
      council = council, ownership_category = ownership_category, ownership_authority = ownership_authority,
      operating_status = operating_status)
  
      append!(table_data, row_data)
    end
    #row_data
  end
  table_data
end

# Defining tasks and responses/ response lengths
target_links = all_links
response_length = length(target_links)
results = Vector{DataFrame}(undef, response_length)

# Collecting results asynchronously
@time asyncmap(target_links; ntasks = 100) do link
  data = get_table_data(link)
  println("$link scraped successfully!")
  return data
end |> (x -> results .= x)

# Wrangling collected results
data = vcat(results...)
data = DataFrame(data)


rename!(data, Dict("facility_id" => "#",
                   "facility_code" => "Facility Code",
                   "facility_name" => "Facility Name",
                   "facility_type" => "Facility Type",
                   "region" => "Region",
                   "council" => "Council",
                   "ownership_category" => "Ownership Category",
                   "ownership_authority" => "Ownership Authority",
                   "operating_status" => "Operating Status")) # rename! does it inplace. `rename` creates a copy


for col in names(data)
    println("Column: $col, Type: $(eltype(data[!, col]))")
end


@time XLSX.writetable("./Output/HFRS Julia 18 Mar 24.xlsx", collect(eachcol(data)),
                      names(data), overwrite = true)