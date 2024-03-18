using Gumbo, HTTP, AbstractTrees, Dates

my_get(uri) = String(read(`curl --silent $uri`))

const ifilter = Iterators.filter

userid = if length(ARGS) ≥ 1
    ARGS[1]
else
    @warn "No userid supplied; you're getting Dave's recipes"
    "15935"
end

const baseurl = "https://www.brewtoad.com"

function recipe_links(userid)
    recipelinks = String[]
    pages = [baseurl * "/users/" * string(userid) * "/recipes"]
    while !isempty(pages)
        page = parsehtml(my_get(pop!(pages)))
        for node in PreOrderDFS(page.root)
            node isa HTMLElement{:a} || continue
            class = get(attrs(node), "class", "")
            if class == "recipe-link"
                link = attrs(node)["href"]
                push!(recipelinks, link)
                println(link)
            elseif class == "next_page"
                push!(pages, baseurl * attrs(node)["href"])
                println("Next page: ", attrs(node)["href"])
            end
        end
    end
    return recipelinks
end

function process_recipe(recipe_link)
    # recipe_html = String(HTTP.request("GET", baseurl * recipe_link).body)
    recipe_html = my_get(baseurl * recipe_link)
    recipe = parsehtml(recipe_html)
    recipe_str = match(r"/recipes/(.*)", recipe_link).captures[1]
    recipe_dir = "recipes/$recipe_str"
    mkpath(recipe_dir)

    title = strip(first(ifilter(n -> n isa HTMLText && n.parent isa HTMLElement{:h1},
                                PreOrderDFS(recipe.root))).text)

    println("processing recipe \"$title\" → $recipe_dir")

    open(joinpath(recipe_dir, "$recipe_str.html"), "w") do f
        println("  writing HTML for $title to $(f.name)...")
        write(f, recipe_html)
    end
    
    open(joinpath(recipe_dir, "$recipe_str.xml"), "w") do f
        println("  writing XML for $title to $(f.name)...")
        # write(f, HTTP.request("GET", baseurl * recipe_link * ".xml").body)
        write(f, my_get(baseurl * recipe_link * ".xml"))
    end
    
    brewlogs = extract_brewlogs(recipe_link)
    foreach(process_brewlog, brewlogs)

end

function extract_brewlogs(recipe_link)
    # brewlogs = parsehtml(String(HTTP.request("GET",
    #                                          baseurl * recipe_link * "/brew-logs").body))
    brewlogs = parsehtml(my_get(baseurl * recipe_link * "/brew-logs"))

    brewlog_links = 
        [attrs(n)["href"]
         for n
         in PreOrderDFS(brewlogs.root)
         if n isa HTMLElement{:a} && occursin(r"brew-logs/", get(attrs(n), "href", ""))]

end

function process_brewlog(brewlog_link)
    # brewlog_html = String(HTTP.request("GET", baseurl * brewlog_link).body)
    brewlog_html = my_get(baseurl * brewlog_link)
    brewlog = parsehtml(brewlog_html)

    recipe_str = match(r"/recipes/(.*)/brew-logs/.*", brewlog_link).captures[1]
    recipe_dir = "recipes/$recipe_str"

    date = [n.text for n in PreOrderDFS(brewlog.root)
            if n isa HTMLText && n.parent isa HTMLElement{:strong}]
    date = try 
        Date(first(date), dateformat"U d, y")
    catch
        date
    end

    path = joinpath(recipe_dir, "brewlogs")
    mkpath(path)
    open(joinpath(path, "$date.html"), "w") do f
        println("  brewlog $path/$date.html")
        write(f, brewlog_html)
    end
end


function main(userid)

    recipes = recipe_links(userid)
    
    # don't bother waiting on the HTTP requests :)
    @sync begin
        for recipe in recipes
            @async process_recipe(recipe)
        end
    end

end

main(userid)
