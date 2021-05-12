
using Stan
using StanSample
using DataFrames
using Distributions
using RDatasets
using Gadfly


function filter_captures!(df, pars)
    filter!(row -> occursin.(pars, row.Parameters),  df)
end

function RegexPars(pars)
	subscript_pars = ["$x\\[.]" for x in pars]
	combined = vcat(pars, subscript_pars)
	final_pars = ["\\b$x\\b" for x in combined]
	final_pars = Regex(join(final_pars, "|"))

	return final_pars
end


function summarize(model; pars="all", print_all=false)
	if !((pars == "all") | (isa(pars, Array)))
		println("\"pars\" argument should be an array of (symbolic) parameters")
		println("e.g., [:par1, :par2]")
		return
	end

	if isa(pars, Array)
		pars = RegexPars(pars)
	end

	output = read_summary(model)

	output[!, :parameters] = String.(output[!, :parameters])

	colnames = ["Parameters",
					 "Mean",
					 "MCSE",
					 "Std",
					 "5%",
					 "50%",
					 "95%",
					 "ESS",
					 "N_Effs",
					 "R̂"]
	rename!(output, Symbol.(colnames))

	if pars != "all"
		filter_captures!(output, pars)
	end

	if !print_all
		output = output[!, Not([8, 9])]
		for col in names(output)[2:size(output)[2]]
			output[!, col] = round.(output[!, col], digits=2)
		end
	else
		for col in names(output)[2:size(output)[2]]
			output[!, col] = round.(output[!, col], digits=2)
		end
	end
	return output
end




# samples = read_samples(sm; output_format =:dataframe,
# 	include_internals =:true);



function pairs1(model)
	samples = read_samples(sm; output_format =:dataframe,
	include_internals =:true);
	set_default_plot_size(20cm, 20cm)
	varnames = map(string, names(samples))
	varnames = varnames[Not(1:7)]
	l = length(varnames)
	plots = Matrix{Plot}(undef, l , l)
	for i ∈ 1:l
		for j ∈ 1:l
			if i == j
				p = plot(samples,
					 x = samples[!, i],
					 Geom.histogram,
					 Guide.xlabel(varnames[i]))
				plots[i, j] = p
			else
				p = plot(samples,
					x = samples[!, i],
					y = samples[!, j],
					Geom.point,
					Guide.xlabel(varnames[i]),
					Guide.ylabel(varnames[j]))
				plots[i, j] = p
			end
		end
	end
	gridstack(plots)
end

pairs1(samples)



function make_stan_data(df)
	out = Dict()
	for var in names(df)
		get!(out, var, df[!, var])
	end
	get!(out, "N", size(df)[1])

	out
end

