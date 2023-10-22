function PTerror(key)
    errormessages = Dict(
        "missingWindows" => "Missing selection windows. Run setBlank!(...) or setSignal!(...) first.",
        "missingBlank" => "No blank model fitted. Run fitBlanks!(...) first.",
        "missingStandard" => "The data haven't be calibrated. Run fitStandards!(...) first.",
        "missingControl" => "No DRS control parameters set. Run setDRS!(...) first."
    )
    throw(error(errormessages[key]))
end
