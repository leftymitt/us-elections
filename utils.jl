################################################################################
# define general utility functions.
################################################################################

# pandas saves a comma as a thousands-place separator
function fixdata(arr)
	result = DataArray(Int, length(arr))
	for i in 1:length(arr)
		result[i] = parse(Int, join(split(arr[i], ',')))
	end
	return result
end
