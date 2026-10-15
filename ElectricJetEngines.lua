-- Electric Jet Engines
-- Converts the Wheesley, Whittle, and Goliath turbofans to run on
-- ElectricCharge instead of fuel. Optionally rebalances the tech tree.

-- ── Campaign features ─────────────────────────────────────────────────────
-- Each campaign can switch these on or off (Mods menu -> Default Features,
-- or the campaign Feature Editor). No restart-required config toggles needed.
-- Names and descriptions come from localizations/electric_jet_engines.csv.

PM:DefineFeature("Wheesley", { recommended = true })
PM:DefineFeature("Whittle",  { recommended = true })
PM:DefineFeature("Goliath",  { recommended = true })
PM:DefineFeature("TechTree", { recommended = true })

-- ── Electric propellant recipe ────────────────────────────────────────────
-- NewRecipe creates a recipe-style resource (ingredients list).
-- 50 000 EC consumed per propellant recipe unit.

PM.Resources:NewRecipe("ElectricJetPropellant", function(recipe)
    recipe.displayNameKey  = "Resource/DisplayName/ElectricCharge"
    recipe.abbreviationKey = "Resource/Abbreviation/EC"
    recipe.vfxFuelType     = "Electric"
    recipe.ingredients:Add("ElectricCharge", 50000.0)
end)

-- ── Helper: swap propellant on all engine modes, strip fuel containers ────
local function electrifyEngine(part)
    local modes = {}
    part:PatchModule("Module_Engine", function(module)
        module:PatchData("Data_Engine", function(engine)
            for _, mode in pairs(engine.engineModes) do
                modes[#modes + 1] = mode
            end
        end)
    end)

    PM.VSwift:AddPartSwitch(part, function(data)
        data.ActiveVariants = { "standard" }
        data.DefaultActiveVariants = { "standard" }
        data:EnsureVariantSet("propulsion", function(set)
            set.VariantSetLocalizationKey = "ElectricEngines/Variants/Propulsion"
            set:EnsureVariant("standard", function(variant)
                variant.VariantLocalizationKey = "ElectricEngines/Variants/Propulsion/Standard"
            end)
            set:EnsureVariant("electric", function(variant)
                variant.VariantLocalizationKey = "ElectricEngines/Variants/Propulsion/Electric"
                variant:EnsureTransformer("EngineModeSwapper", function(swapper)
                    for _, mode in pairs(modes) do
                        swapper:Append(mode)
                        swapper[mode.engineID].propellant.mixtureName = "ElectricJetPropellant"
                    end
                end)
                variant:EnsureTransformer("ResourceContainerRemover", function(remover)
                    remover.Containers = { "MethaneAir", "Methane", "LiquidFuel" }
                end)
            end)
        end)
    end)
end

-- ── Part patches ──────────────────────────────────────────────────────────

PM.Parts:Patch("ElectricWheesley")
    :Feature("Wheesley")
    :Named("engine_1v_turbofan_methane_wheesley")
    :Do(electrifyEngine)

PM.Parts:Patch("ElectricWhittle")
    :Feature("Whittle")
    :Named("engine_0v_methane_whittle")
    :Do(electrifyEngine)

PM.Parts:Patch("ElectricGoliath")
    :Feature("Goliath")
    :Named("engine_2v_turbofan_methane_goliath")
    :Do(electrifyEngine)

-- ── Tech tree rebalance ───────────────────────────────────────────────────

-- Each node needs TechTree on, plus any engine features passed after the engines.
local function electricAviationNode(id, x, y, cost, prerequisites, engines, ...)
    PM.Science:NewTechNode(id, function(node)
        node.NameLocKey = "ElectricJetEngines/TechNodes/Names/" .. id
        node.DescriptionLocKey = "ElectricJetEngines/TechNodes/Descriptions/" .. id
        node.IconID = "ICO-RDCenter-Plane-24x"
        node.RequiredSciencePoints = cost
        for _, prerequisite in ipairs(prerequisites) do
            node.RequiredTechNodeIDs:Append(prerequisite)
        end
        node.TechTreePosition.x = x
        node.TechTreePosition.y = y
        for _, engine in ipairs(engines) do
            node.UnlockedVariants:Append({ PartName = engine, VariantSetId = "propulsion", VariantId = "electric" })
        end
    end):Feature("TechTree", ...)
end

electricAviationNode("tNode_1v_electric_aviation", 1080, 90, 100,
    { "tNode_1v_aero_02" },
    { "engine_1v_turbofan_methane_wheesley" },
    "Wheesley")
electricAviationNode("tNode_2v_electric_drones", 2520, -20, 650,
    { "tNode_0v_aero" },
    { "engine_0v_methane_whittle" },
    "Whittle")
electricAviationNode("tNode_3v_electric_aviation_03", 3960, 90, 4000,
    { "tNode_3v_aero_03" },
    { "engine_2v_turbofan_methane_goliath" },
    "Goliath")
