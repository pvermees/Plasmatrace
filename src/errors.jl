const errormessages = Dict(
    "missingWindows" => "Missing selection windows. Run setBlank!(...) or setSignal!(...) first.",
    "missingBlank" => "No blank model fitted. Run fitBlanks!(...) first.",
    "missingStandard" => "The data haven't be calibrated. Run fitStandards!(...) first."
)

function PTerror(key)
    throw(error(errormessages[key]))
end
