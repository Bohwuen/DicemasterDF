-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local SharedMedia     = LibStub("LibSharedMedia-3.0")

local VERSION = 1

-------------------------------------------------------------------------------
local DB_DEFAULTS = {
	
	global = {
		version     = nil;
		showUses    = true;
		hideInspect = false; -- hide inspect frame when panel is hidden
		hideStats   = false; -- hide stats button from inspect frame.
		hidePet   = false; -- hide pet portrait frame from inspect frame.
		hideTips	= true; -- turn enhanced tooltips on for newbies
		hideTracker = false; -- hide the roll tracker.
		trackerAnchor = "RIGHT";
		hideTypeTracker = false;
		allowSounds = true;
		enableEmojis = true;
		enableRoundBanners = true;
		enableMapNodes = true;
		enableTurnTracker = true;
		talkingHeads = true;
		healthIcons = false; 
		allowSounds = true;
		allowEffects = true;
		allowIcons = true;
		allowAssistantTalkingHeads = true;
		allowBuffs = true;
		bloodEffects = true;
		miniFrames = false;
		bank = {};
		savedBuffs = {};
		lastSplashShown = nil;
	};
	
	char = { 
		minimapicon = {
			hide = false;
		};
		hidepanel     = false;
		uiScale       = 0.75;
		trackerScale  = 0.6;
		trackerKeybind = nil;
		showRaidRolls = false;
		enableD10 = false;
		statusSerial  = 1;
		traitSerials  = {};
	};
	
	profile = {
		charges = {
			enable  = false;
			name    = "Recurso personalizado";
			color   = {1,1,1};
			count   = 0;
			max     = 3;
			tooltip = "Representa la cantidad de recursos personalizados del personaje para emplear en rasgos.";
			symbol	= "charge-orb";
			flash   = true;
			pos		= false;
		};
		morale = {
			enable  = false;
			name    = "Barra de progreso";
			count   = 100;
			step    = 5;
			tooltip = "Una barra de progreso personalizada que se muestra al grupo.";
			color   = {1,1,0};
			symbol  = "WoWUI";
			scale   = 0.75;
		};
		health       = 10;
		healthMax    = 10;
		mana		 = 20;
		manaMax 	 = 20;
		manaType	 = "Mana";
		armor        = 0;
		traits       = {};
		pet	= {
			enable  = false;
			name 	= "Nombre de Mascota";
			type    = "Pet";
			icon 	= "Interface/Icons/inv_misc_questionmark";
			model 	= 0;
			scale 	= 0.15;
			health       = 5;
			healthMax    = 5;
			armor        = 0;
			happiness	 = 3;
			foodTypes 	 = { "Carne", "Pescado", "Fruta", "Hongos", "Pan", "Queso" };
		};
		inventory	 = {};
		inventoryIcon = "Interface/Buttons/Button-Backpack-Up";
		shop		 = {};
		shopIcon = "Interface/Icons/garrison_building_tradingpost";
		shopName = false;
		shopModel = false;
		hideShop = false;
		currency     = {
			{
				name = "DiceMaster Coins";
				icon = "Interface/AddOns/DiceMaster/Texture/token";
				value = 0;
				guid = 0;
			};
		};
		currencyActive = 1;
		recipes			 = {};
		skills			 = {};
		alignment		 = "(Ninguno)";
		buffsActive  	 = {};
		level        = 1;
		experience   = 0;
		dice 		 = "1D20+0";
		mapNodes	 = {};
		framePositions = {};
		dm5Imported = false;
	} 
}

-- Initialize traits.
do
	local numbers = { "Uno", "Dos", "Tres", "Cuatro", "Cinco" }
	for i = 1, 5 do
		 
		DB_DEFAULTS.profile.traits[i] = {
			name   = "Rasgo " .. numbers[i];                    -- name of trait
			usage  = Me.TRAIT_USAGE_MODES[1];                   -- usage, see USAGE_MODES
			range  = Me.TRAIT_RANGE_MODES[1];                   -- usage, see RANGE_MODES
			castTime = Me.TRAIT_CAST_TIME_MODES[1];				-- cast time, see CAST_TIME_MODES
			cooldown = Me.TRAIT_COOLDOWN_MODES[1];				-- cooldown time, see COOLDOWN_MODES
			desc   = "Escribe la descripción del Rasgo aqui."; -- trait description
			approved = false;									-- trait approved
			officers = {};										-- approved by
			icon   = "Interface/Icons/inv_misc_questionmark";   -- trait icon texture path
			effects = {};
			traitIndex = nil;
		}
		
		DB_DEFAULTS.char.traitSerials[i] = 1 -- used to optimize out duplicate requests
	end
	if Me.PermittedUse() then
		DB_DEFAULTS.profile.traits[5].name = "Equipment Slot";
	end
end

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
Me.configOptions = {
	type  = "group";
	order = 1;
	args = { 
		-----------------------------------------------------------------------
		header = {
			order = 0;
			name  = "Configurar las características de Dicemaster.";
			type  = "description";
		};
		
		mmicon = {
			order = 1;
			name  = "Habilitar botón de minimapa";
			desc  = "Habilitar botón de minimapa.";
			type  = "toggle";
			set   = function( info, val ) Me.MinimapButton:Show( val ) end;
			get   = function( info ) return not Me.db.char.minimapicon.hide end;
		};
 
		uiScale = {
			order     = 4;
			name      = "Escala de interfaz";
			desc      = "Cambiar el tamaño del panel de dados, las barras de salud y recurso, el objetivo y los marcos de la barra de progreso.";
			type      = "range";
			min       = 0.25;
			max       = 10;
			softMax   = 4;
			isPercent = true;
			set = function( info, val ) 
				Me.db.char.uiScale = val;
				Me.ApplyUiScale()
			end;
			get = function( info ) return Me.db.char.uiScale end;
		};
		
		showUses = {
			order = 5;
			name  = "Muestra los usos restantes de los rasgos";
			desc  = "Muestra los usos restantes d elos rasgos en el panel de dados.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.showUses = val
				Me.configOptions.args.resetUses.hidden = not val
				Me.UpdatePanelTraits()
			end;
			get = function( info ) return Me.db.global.showUses end;
		};
		
		resetUses = {
			order = 6;
			name  = "Reiniciar los usos de rasgos.";
			desc  = "Reinicia el enfriamiento de los rasgos del panel de dados.";
			type  = "execute";
			hidden   = true;
			width = "normal";
			func  = function()
				for i = 1, #DiceMasterChargesFrame.traits do
					local traitButton = DiceMasterChargesFrame.traits[i]
					local traitIndex = traitButton.traitIndex
					local trait = Me.Profile.traits[ traitIndex ]
					local usage = trait.usage or "PASSIVE";
					
					if usage:find("USE") then
						local usesTotal = usage:gsub("USE", "")
						traitButton.count:SetText( usesTotal )
						traitButton.icon:SetVertexColor( 1, 1, 1 )
						traitButton.notCastable = false;
					end
					
					traitButton.cooldown:SetCooldown( 0, 0 )
					traitButton.cooldown.text:SetText("")
					traitButton.cooldown.text:Hide()
				end
			end;
		};
		
		hideInspect = {
			order = 7;
			name  = "Oculta el marco de inspección";
			desc  = "Oculta el marco de inspección mientras DiceMaster esté oculto.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.hideInspect = val
				Me.Inspect_Open( Me.inspectName )
				-- refresh hidden status.
			end;
			get = function( info ) return Me.db.global.hideInspect end;
		};
		
		hideStats = {
			order = 8;
			name  = "Ocultar botón de inspección";
			desc  = "Ocultar Botón de inspección mientras DiceMaster está oculto.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.hideStats = val
				Me.Inspect_Open( Me.inspectName )
				-- refresh hidden status.
			end;
			get = function( info ) return Me.db.global.hideStats end;
		};
		
		hidePet = {
			order = 9;
			name  = "Ocultar marco de mascota del objetivo";
			desc  = "Ocultar marco de mascota del objetivo mientras DiceMaster está oculto.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.hidePet = val
				Me.Inspect_Open( Me.inspectName )
				-- refresh hidden status.
			end;
			get = function( info ) return Me.db.global.hidePet end;
		};
		
		hideTips = {
			order = 10;
			name  = "Mejorar Tooltip";
			desc  = "Habilitar definiciones útiles de términos de DiceMaster junto a las descripciones de rasgos.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.hideTips = val
			end;
			get = function( info ) return Me.db.global.hideTips end;
		};
		
		hideTypeTracker = {
			order = 11;
			name  = "Activar seguimiento de escritura";
			desc  = "Habilitar el Rastreador de Escritura para alertarte cuando los miembros del grupo están escribiendo en decir, acción, grupo y banda.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.hideTypeTracker = val
				Me.PostTracker_Init()
			end;
			get = function( info ) return Me.db.global.hideTypeTracker end;
		};
		
		enableTurnTracker = {
			order = 12;
			name  = "Activar seguimiento de turnos de combate";
			desc  = "Muestra una ventana de seguimiento de turnos de combate cuando este empieza.";
			width = "full";
			type  = "toggle";
			set = function( info, val ) 
				Me.db.global.enableTurnTracker = val
				if not val then
					DiceMasterTurnTracker:Hide()
				end
			end;
			get = function( info ) return Me.db.global.enableTurnTracker end;
		};
		
		allowSounds = {
			order = 13;
			name  = "Admitir sonidos de otros jugadores";
			desc  = "Admite escuchar sonidos emitidos por otros jugadores.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.allowSounds = val
			end;
			get = function( info ) return Me.db.global.allowSounds end;
		};
		
		allowEffects = {
			order = 14;
			name  = "Admitir efectos de otros jugadores";
			desc  = "Admitir ver los efectos de pantalla de otros jugadores.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.allowEffects = val
			end;
			get = function( info ) return Me.db.global.allowEffects end;
		};
		
		allowIcons = {
			order = 15;
			name  = "Mostrar iconoes en el chat";
			desc  = "Mostrar los iconos que los jugadores muestran en el chat público.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.allowIcons = val
			end;
			get = function( info ) return Me.db.global.allowIcons end;
		};
		
		enableEmojis = {
			order = 16;
			name  = "Activar autocompletado de emoji.";
			desc  = "Muestra un campo de autocompletado sobre el chat quenco empiezas a escribir un emoji.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.enableEmojis = val
			end;
			get = function( info ) return Me.db.global.enableEmojis end;
		};
		
		enableRoundBanners = {
			order = 17;
			name  = "Admitir estandartes";
			desc  = "Admitir que el lider del grupo te encia estandartes animados cuando sea tu turno.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.enableRoundBanners = val
			end;
			get = function( info ) return Me.db.global.enableRoundBanners end;
		};
		
		enableMapNodes = {
			order = 18;
			name  = "Mostrar nodos de mapa de lider";
			desc  = "Muetsra los nodos de mapa del lider cuando estás en grupo o banda.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.enableMapNodes = val
				Me.UpdateAllMapNodes()
			end;
			get = function( info ) return Me.db.global.enableMapNodes end;
		};

		enableD10 = {
			order = 19;
			name  = "Habilitar modo D10";
			desc  = "Habilitar modo Dados 10.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.enableD10 = val
			end;
			get = function( info ) return Me.db.global.enableD10 end;
		};
		
		headerFrames = {
			order = 20;
			name  = " ";
			type  = "description";
		};
		
		discordLink = {
			order = 21;
			name  = "Discord";
			type  = "input";
			width = "double";
			get   = function( info ) return "https://discord.gg/zCRJVQj" end;
		};
	};
}

Me.configOptionsCharges = {
	type  = "group";
	order = 1;
	args = { 
		-----------------------------------------------------------------------
		header = {
			order = 0;
			name  = "Configura las barras de Salud, Maná o progreso.";
			type  = "description";
		};
		
		healthIcons = {
			order = 10;
			name  = "Use Hearthstone Style Meters Instead";
			desc  = "Toggles whether to use the default health bar or the Hearthstone style health and mana meters.|n|n(The meters anchor to the PlayerFrame and TargetFrame by default.)";
			width = "full";
			type  = "toggle";
			set = function( info, val ) 
				Me.db.global.healthIcons = val
				Me.RefreshHealthbarFrame( DiceMasterChargesFrame.healthbar, Me.db.profile.health, Me.db.profile.healthMax, Me.db.profile.armor )
				Me.RefreshManabarFrame( DiceMasterChargesFrame.manabar, Me.db.profile.mana, Me.db.profile.manaMax )
				Me.Inspect_Open( UnitName( "target" ))
			end;
			get = function( info ) return Me.db.global.healthIcons end;
			hidden = true;
		};
		
		healthGroup = {
			name     = "Barra de salud";
			inline   = true;
			order    = 12;
			type     = "group";
			args = {
				healthCurrent = {
					order = 10;
					name  = "Salud actual";
					desc  = "La cantidad de número de puntos de salud que el personaje posee.";
					type  = "range"; 
					min   = 0;
					max   = 1000;
					step  = 1;
					set   = function( info, val ) 
						Me.db.profile.health = val
						Me.RefreshHealthbarFrame( DiceMasterChargesFrame.healthbar, Me.db.profile.health, Me.db.profile.healthMax, Me.db.profile.armor )
	
						Me.BumpSerial( Me.db.char, "statusSerial" )
						Me.Inspect_ShareStatusWithParty() 
					end;
					get   = function( info ) return Me.db.profile.health end;
				}; 
			  
				healthMax = {
					order = 20;
					name  = "Salud Máxima";
					desc  = "La cantidad Máxima de salud que el personaje puede poseer.";
					type  = "range"; 
					min   = 1;
					max   = 1000;
					step  = 1;
					set   = function( info, val ) 
						Me.db.profile.healthMax = val
						Me.configOptionsCharges.args.healthGroup.args.healthCurrent.max = val
						if Me.db.profile.health > Me.db.profile.healthMax then
							Me.db.profile.health = Me.db.profile.healthMax
						end
						Me.RefreshHealthbarFrame( DiceMasterChargesFrame.healthbar, Me.db.profile.health, Me.db.profile.healthMax, Me.db.profile.armor )
	
						Me.BumpSerial( Me.db.char, "statusSerial" )
						Me.Inspect_ShareStatusWithParty() 
					end;
					get   = function( info ) return Me.db.profile.healthMax end;
				}; 
			};
		};
		
		manaGroup = {
			name     = "Barra de maná";
			inline   = true;
			order    = 13;
			type     = "group";
			args = {
				manaCurrent = {
					order = 10;
					name  = "Maná actual";
					desc  = "La cantidad de maná actual que el personaje posee.";
					type  = "range"; 
					min   = 0;
					max   = 1000;
					step  = 1;
					set   = function( info, val ) 
						Me.db.profile.mana = val
						Me.RefreshManabarFrame( DiceMasterChargesFrame.manabar, Me.db.profile.mana, Me.db.profile.manaMax )
	
						Me.BumpSerial( Me.db.char, "statusSerial" )
						Me.Inspect_ShareStatusWithParty() 
					end;
					get   = function( info ) return Me.db.profile.mana end;
				}; 
			  
				manaMax = {
					order = 20;
					name  = "Maná Máximo";
					desc  = "La cantidad máxima de puntos de maná que el personaje puede poseer.";
					type  = "range"; 
					min   = 1;
					max   = 1000;
					step  = 1;
					set   = function( info, val ) 
						Me.db.profile.manaMax = val
						Me.configOptionsCharges.args.manaGroup.args.manaCurrent.max = val
						if Me.db.profile.mana > Me.db.profile.manaMax then
							Me.db.profile.mana = Me.db.profile.manaMax
						end
						Me.RefreshManabarFrame( DiceMasterChargesFrame.manabar, Me.db.profile.mana, Me.db.profile.manaMax )
	
						Me.BumpSerial( Me.db.char, "statusSerial" )
						Me.Inspect_ShareStatusWithParty() 
					end;
					get   = function( info ) return Me.db.profile.manaMax end;
				};
				
				manaType = {
					order = 70;
					name  = "Tipo de recurso";
					desc  = "Elige tipo de recurso.";
					type  = "select"; 
					style = "dropdown";
					values = {
						["Mana"] = "Maná",
						["Energy"] = "Energía",
						["Focus"] = "Foco",
						["Rage"] = "Ira",
						["RunicPower"] = "Poder Rúnico",
						["None"] = "(Ninguno)",
					};
					set   = function( info, val ) 
						Me.db.profile.manaType = val
						local statusBarTexture = DiceMasterChargesFrame.manabar:GetStatusBarTexture();
						if val:find("Ninguno") then
							-- statusBarTexture:SetAtlas( "UI-HUD-UnitFrame-Player-PortraitOff-Bar-" .. val );
						else
							statusBarTexture:SetAtlas( "UI-HUD-UnitFrame-Player-PortraitOff-Bar-" .. val );
						end
						Me.OnChargesChanged()
					end;
					get   = function( info ) return Me.db.profile.manaType end;
				};
			};
		};
	
		enableCharges = {
			order = 14;
			name  = "Activar barra de recurso";
			desc  = "Activar el uso de la barra de recursos extra.";
			width = "full";
			type  = "toggle";
			set = function( info, val ) 
				Me.db.profile.charges.enable = val 
				Me.configOptionsCharges.args.chargesGroup.hidden = not val
				Me.OnChargesChanged() 
			end;
			get = function( info ) return Me.db.profile.charges.enable end;
		};

		chargesGroup = {
			name     = "Barra de recurso";
			inline   = true;
			order    = 15;
			type     = "group";
			hidden   = true;
			args = {
				chargesName = {
					order = 20;
					name  = "Nombre del recurso";
					desc  = "Nombra el recurso personalizado. Ejemplos: Poder sagrado, Ira, Adrenalina.";
					type  = "input";
					set = function( info, val ) 
						Me.db.profile.charges.name = val
						Me.OnChargesChanged()
					end;
					get = function( info ) return Me.db.profile.charges.name end;
				};
				
				chargesColor = {
					order = 30;
					name  = "Color de recurso";
					desc  = "Color de la barra de recurso.";
					type  = "color";
					set = function( info, r, g, b ) 
						Me.db.profile.charges.color = {r,g,b}
						Me.OnChargesChanged()
					end;
					get = function( info ) 
						return Me.db.profile.charges.color[1],
							   Me.db.profile.charges.color[2],
							   Me.db.profile.charges.color[3]
					end;
				};
			  
				chargesMax = {
					order = 40;
					name  = "Recurso máximo";
					desc  = "el número máximo de recurso personalizado obtenible.";
					type  = "range"; 
					hidden = false;
					min   = 1;
					max   = 8;
					step  = 1;
					set   = function( info, val ) 
						Me.db.profile.charges.max = val
						Me.OnChargesChanged()
					end;
					get   = function( info ) return Me.db.profile.charges.max end;
				}; 
				
				chargesMaxTwo = {
					order = 50;
					name  = "Recurso máximo";
					desc  = "El número máximo de recursos que pueden ser acumulados.";
					type  = "range";
					hidden = true;
					min   = 1;
					max   = 100;
					step  = 1;
					set   = function( info, val ) 
						Me.db.profile.charges.max = val
						if Me.db.profile.charges.count > Me.db.profile.charges.max then
							Me.db.profile.charges.count = Me.db.profile.charges.max
						end
						Me.OnChargesChanged()
					end;
					get   = function( info ) return Me.db.profile.charges.max end;
				}; 
				
				chargesTooltip = {
					order = 60;
					name  = "Descripción de recurso";
					desc  = "La descripción del recurso que se muestra en el marco.";
					type  = "input";
					width = "double";
					multiline = 3;
					set = function( info, val ) 
						Me.db.profile.charges.tooltip = val
						Me.OnChargesChanged()
					end;
					get = function( info ) return Me.db.profile.charges.tooltip end;
				};
				
				chargesSymbol = {
					order = 70;
					name  = "Apariencia de barra de recurso";
					desc  = "La apariencia personalizada de la barra de recurso.";
					type  = "select"; 
					style = "dropdown";
					values = {
						["charge-orb"] = "Orbes",
						["charge-fire"] = "Ascuas ardientes",
						["charge-rune"] = "Runas de Caballero de la muerte",
						["charge-shadow"] = "Runas de sombra",
						["charge-soulshards"] = "Fragmentos de alma",
						["charge-hourglass"] = "Relojes de arena",
						["Air"] = "Aire",
						["Ice"] = "Hielo",
						["Fire"] = "Fuego",
						["Rock"] = "Roca",
						["Water"] = "Agua",
						["Meat"] = "Carne",
						["UndeadMeat"] = "Carne podrida",
						["WoWUI"] = "Genérico",
						["WoodPlank"] = "Tabla de madera",
						["WoodWithMetal"] = "Madera con metal",
						["Darkmoon"] = "Luna negra",
						["MoltenRock"] = "Roca fundida",
						["Alliance"] = "Alianza",
						["Horde"] = "Horda",
						["Amber"] = "Ámbar",
						["Druid"] = "Druida",
						["FancyPanda"] = "Pandaren",
						["Mechanical"] = "Mechanico",
						["LightningCharges"] = "Relámpago",
						["Map"] = "Mapa",
						["InquisitionTorment"] = "Inquisidor",
						["Bamboo"] = "Bambú",
						["Onyxia"] = "Onyxia",
						["StoneDesign"] = "Diseño en piedra",
						["NaaruCharge"] = "Naaru",
						["ShadowPaladinBar"] = "Paladin Oscuro",
						["Xavius"] = "Pesadilla de Xavius",
						["BulletBar"] = "Balas",
						["Azerite"] = "Azerita",
						["Chogall"] = "Cho'gall",
						["FuelGauge"] = "Contenedor de Fuel",
						["FelCorruption"] = "Corrupción Vil",
						["Murozond"] = "Reloj de arena de Murozond",
						["Pride"] = "Orgullo",
						["Rhyolith"] = "Rhyolith",
						["KargathRoarCrowd"] = "Ogro",
						["Meditation"] = "Meditación",
						["Jaina"] = "Jaina",
						["NZoth"] = "N'zoth",
						["sanctum-bar"] = "Santuario Arcano",
						["warden-bar"] = "Guardián",
						["RevendrethAnima"] = "Revendreth",
						["BastionAnima"] = "Bastion",
						["MaldraxxusAnima"] = "Maldraxxus",
						["ArdenwealdAnima"] = "Ardenweald",
						["archer-bar"] = "Arquero",
						["phoenix-bar"] = "Fénix",
						["mana-gems-bar"] = "Gemas de maná",
						["holy-power-bar"] = "Poder Sagrado",
						["balance-bar"] = "Equilibrio",
					};
					set   = function( info, val ) 
						Me.db.profile.charges.symbol = val
						if val:find("charge") then
							if Me.db.profile.charges.max > 8 then
								Me.db.profile.charges.max = 8;
							end
							
							if Me.db.profile.charges.count > 8 then
								Me.db.profile.charges.count = 8
							end
							Me.configOptionsCharges.args.chargesGroup.args.chargesMax.hidden = false
							Me.configOptionsCharges.args.chargesGroup.args.chargesMaxTwo.hidden = true
						else
							Me.configOptionsCharges.args.chargesGroup.args.chargesMax.hidden = true
							Me.configOptionsCharges.args.chargesGroup.args.chargesMaxTwo.hidden = false
						end
						Me.OnChargesChanged()
					end;
					get   = function( info ) return Me.db.profile.charges.symbol end;
				};
				
				chargesFlash = {
					order = 80;
					name  = "Hacer que la barra brille cuando está llena";
					desc  = "Cuando se activa hacer que cuando la barra de recurso se llene brille.";
					width = "full";
					type  = "toggle";
					set = function( info, val ) 
						Me.db.profile.charges.flash = val
						Me.OnChargesChanged() 
					end;
					get = function( info ) return Me.db.profile.charges.flash end;
				};
				
				chargesPos = {
					order = 90;
					name  = "Anclar bajo la barra de salud";
					desc  = "Mueve la barra de recursos bajo la barra de salud..";
					width = "full";
					type  = "toggle";
					set = function( info, val ) 
						Me.db.profile.charges.pos = val
						Me.OnChargesChanged()
					end;
					get = function( info ) return Me.db.profile.charges.pos end;
				};
			};
		};
	};
}

Me.configOptionsProgressBar = {
	type  = "group";
	order = 1;
	args = { 
		-----------------------------------------------------------------------
		header = {
			order = 0;
			name  = "Configurar el marco de barra de progreso.";
			type  = "description";
		};
		
		enableMorale = {
			order = 15;
			name  = "Activar barra de progreso";
			desc  = "Activar la barra de progreso en grupo cuando el lider del grupo la active.";
			width = "full";
			type  = "toggle";
			set = function( info, val ) 
				Me.db.profile.morale.enable = val 
				Me.RefreshMoraleFrame() 
			end;
			get = function( info ) return Me.db.profile.morale.enable end;
		};
		
		moraleGroup = {
			name     = "Dungeon Master Settings";
			inline   = true;
			order    = 16;
			type     = "group";
			args = {
				header = {
					order = 0;
					name  = "These settings only take effect when you are the leader of your party or raid.";
					type  = "description";
				};
			
				moraleName = {
					order = 20;
					name  = "Progress Bar Name";
					desc  = "Name of the progress bar. Examples: Morale, Sanity, Shield Integrity.";
					type  = "input";
					set = function( info, val ) 
						Me.db.profile.morale.name = val
						Me.RefreshMoraleFrame()
					end;
					get = function( info ) return Me.db.profile.morale.name end;
				};
				
				moraleColor = {
					order = 30;
					name  = "Progress Bar Color";
					desc  = "Color of the progress bar.";
					type  = "color";
					set = function( info, r, g, b ) 
						Me.db.profile.morale.color = {r,g,b}
						Me.RefreshMoraleFrame()
					end;
					get = function( info ) 
						return Me.db.profile.morale.color[1],
							   Me.db.profile.morale.color[2],
							   Me.db.profile.morale.color[3]
					end;
				};
				
				moraleSymbol = {
					order = 40;
					name  = "Progress Bar Skin";
					desc  = "Custom skin for the progress bar.";
					type  = "select"; 
					style = "dropdown";
					values = {
						["morale-bar"] = "League of Lordaeron",
						["Air"] = "Air",
						["Ice"] = "Ice",
						["Fire"] = "Fire",
						["Rock"] = "Rock",
						["Water"] = "Water",
						["Meat"] = "Meat",
						["UndeadMeat"] = "Undead Meat",
						["WoWUI"] = "Generic",
						["WoodPlank"] = "Wood Plank",
						["WoodWithMetal"] = "Wood with Metal",
						["Darkmoon"] = "Darkmoon",
						["MoltenRock"] = "Molten Rock",
						["Alliance"] = "Alliance",
						["Horde"] = "Horde",
						["Amber"] = "Amber",
						["Druid"] = "Druid",
						["FancyPanda"] = "Fancy Pandaren",
						["Mechanical"] = "Mechanical",
						["Map"] = "Map",
						["InquisitionTorment"] = "Inquisitor",
						["Bamboo"] = "Bamboo",
						["Onyxia"] = "Onyxia",
						["StoneDesign"] = "Stone Design",
						["NaaruCharge"] = "Naaru",
						["ShadowPaladinBar"] = "Shadow Paladin",
						["Xavius"] = "Xavius Nightmare",
						["BulletBar"] = "Bullets",
						["Azerite"] = "Azerite",
						["Chogall"] = "Cho'gall",
						["FuelGauge"] = "Fuel Gauge",
						["FelCorruption"] = "Fel Corruption",
						["Murozond"] = "Murozond Hourglass",
						["Pride"] = "Pride",
						["Rhyolith"] = "Rhyolith",
						["KargathRoarCrowd"] = "Ogre",
						["Meditation"] = "Meditation",
						["Jaina"] = "Jaina",
						["NZoth"] = "N'zoth",
						["sanctum-bar"] = "Arcane Sanctum",
						["warden-bar"] = "Warden",
						["RevendrethAnima"] = "Revendreth",
						["BastionAnima"] = "Bastion",
						["MaldraxxusAnima"] = "Maldraxxus",
						["ArdenwealdAnima"] = "Ardenweald",
						["archer-bar"] = "Archer",
						["phoenix-bar"] = "Phoenix",
						["mana-gems-bar"] = "Mana Gems",
						["holy-power-bar"] = "Holy Power",
						["balance-bar"] = "Balance",
					};
					set   = function( info, val ) 
						Me.db.profile.morale.symbol = val
						Me.RefreshMoraleFrame()
					end;
					get   = function( info ) return Me.db.profile.morale.symbol end;
				}; 
				
				moraleTooltip = {
					order = 50;
					name  = "Progress Bar Description";
					desc  = "A description for the progress bar tooltip.";
					type  = "input";
					multiline = 3;
					width = "full";
					set = function( info, val ) 
						Me.db.profile.morale.tooltip = val
						Me.RefreshMoraleFrame()
					end;
					get = function( info ) return Me.db.profile.morale.tooltip end;
				};
				
				moraleCount = {
					order = 60;
					name  = "Default Value";
					desc  = "The default value of the progress bar.";
					type  = "range"; 
					min   = 0;
					max   = 100;
					step  = 1;
					set   = function( info, val ) 
						Me.db.profile.morale.count = val
						Me.RefreshMoraleFrame( val )
					end;
					get   = function( info ) return Me.db.profile.morale.count end;
				}; 
				
				moraleStep = {
					order = 70;
					name  = "Increase/Decrease Value";
					desc  = "The amount that is added/removed when the progress bar is clicked.";
					type  = "range"; 
					min   = 1;
					max   = 100;
					step  = 1;
					set   = function( info, val ) 
						Me.db.profile.morale.step = val
						Me.RefreshMoraleFrame()
					end;
					get   = function( info ) return Me.db.profile.morale.step end;
				}; 
				
				moraleScale = {
					order     = 80;
					name      = "Progress Bar Scale";
					desc      = "Change the size of the Progress Bar frame.";
					type      = "range";
					min       = 0.25;
					max       = 10;
					softMax   = 4;
					isPercent = true;
					set = function( info, val ) 
						Me.db.profile.morale.scale = val;
						Me.ApplyUiScale()
					end;
					get = function( info ) return Me.db.profile.morale.scale end;
				}; 
			};
		};
	};
}

Me.configOptionsManager = {
	type  = "group";
	order = 1;
	args = { 
		-----------------------------------------------------------------------
		header = {
			order = 0;
			name  = "Configure the Dungeon Manager settings.";
			type  = "description";
		};
		
		hideTracker = {
			order = 10;
			name  = "Enable Dungeon Manager";
			desc  = "Enable the Dungeon Manager frame to keep track of your group's rolls, view group-wide notes, and access map nodes.";
			type  = "toggle";
			width = "double";
			set = function( info, val )
				Me.db.global.hideTracker = val
				if val == true then
					DiceMasterRollFrame:Show()
				else
					DiceMasterRollFrame:Hide()
				end
			end;
			get = function( info ) return Me.db.global.hideTracker end;
		};
		
		trackerScale = {
			order     = 20;
			name      = "Dungeon Manager Scale";
			desc      = "The size of the Dungeon Manager frame.";
			type      = "range";
			min       = 0.25;
			max       = 10;
			softMax   = 4;
			isPercent = true;
			set = function( info, val ) 
				Me.db.char.trackerScale = val;
				Me.ApplyUiScale()
			end;
			get = function( info ) return Me.db.char.trackerScale end;
		};
		
		trackerAnchor = {
			order = 30;
			name  = "Details Frame Anchor";
			desc  = "Choose whether the Detail Frame is anchored on the left or right.";
			type  = "select"; 
			style = "radio";
			values = {
				["LEFT"] = "Left",
				["RIGHT"] = "Right",
			};
			set   = function( info, val ) 
				Me.db.global.trackerAnchor = val
				Me.DiceMasterRollDetailFrame_Update()
			end;
			get   = function( info ) return Me.db.global.trackerAnchor end;
		};
		
		trackerKeybind = {
			order     = 40;
			name	  = "Toggle Key";
			desc      = "Set a keybinding for the Dungeon Manager frame.";
			type      = "keybinding";
			set = function( info, val ) 
				Me.db.char.trackerKeybind = val;
				Me.ApplyKeybindings()
			end;
			get = function( info ) return Me.db.char.trackerKeybind end;
		};
	};
}

-------------------------------------------------------------------------------
function Me.SetupDB()
	
	local acedb = LibStub( "AceDB-3.0" )
  
	Me.db = acedb:New( "DiceMaster4_Saved", DB_DEFAULTS )
	
	Me.db.RegisterCallback( Me, "OnProfileChanged", "ApplyConfig" )
	Me.db.RegisterCallback( Me, "OnProfileCopied",  "ApplyConfig" )
	Me.db.RegisterCallback( Me, "OnProfileReset",   "ApplyConfig" )
	 
	local options = Me.configOptions
	local charges = Me.configOptionsCharges
	local progressbar = Me.configOptionsProgressBar
	local dmmanager = Me.configOptionsManager
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable( Me.db )
	profiles.order = 500
	 
	AceConfig:RegisterOptionsTable( "DiceMaster", options )	
	AceConfig:RegisterOptionsTable( "Barras de salud/Maná", charges )	
	AceConfig:RegisterOptionsTable( "Barra de progreso", progressbar )	
	AceConfig:RegisterOptionsTable( "Aministrador de mazmorra", dmmanager )	
	AceConfig:RegisterOptionsTable( "Perfiles de Dicemaster", profiles )
	
	Me.config = AceConfigDialog:AddToBlizOptions( "DiceMaster", "DiceMaster" )
	Me.configCharges = AceConfigDialog:AddToBlizOptions( "Barras de salud/Maná", "Barras de salud/Maná", "DiceMaster" )
	Me.configProgressBar = AceConfigDialog:AddToBlizOptions( "Barra de progreso", "Barra de progreso", "DiceMaster" )
	Me.configManager = AceConfigDialog:AddToBlizOptions( "Aministrador de mazmorra", "Aministrador de mazmorra", "DiceMaster" )
	Me.configProfiles = AceConfigDialog:AddToBlizOptions( "Perfiles de Dicemaster", "Perfiles", "DiceMaster" )
	
	local function CreateLogo( frame )
		local logo = CreateFrame('Frame', nil, frame, BackdropTemplateMixin and "BackdropTemplate")
		logo:SetFrameLevel(4)
		logo:SetSize(64, 64)
		logo:SetPoint('TOPRIGHT', 8, 24)
		logo:SetBackdrop({bgFile = "Interface/AddOns/DiceMaster/Texture/logo"})
		frame.logo = logo
	end
	
	CreateLogo( Me.config )
	CreateLogo( Me.configCharges )
	CreateLogo( Me.configProgressBar )
	CreateLogo( Me.configManager )
	CreateLogo( Me.configProfiles )
end

local interfaceOptionsNeedsInit = true
-------------------------------------------------------------------------------
-- Open the configuration panel.
--
function Me.OpenConfig() 
	Me.configOptionsCharges.args.chargesGroup.hidden = not Me.db.profile.charges.enable
	Me.configOptions.args.resetUses.hidden = not Me.db.profile.showUses
	Me.configOptionsCharges.args.healthGroup.args.healthCurrent.max = Me.db.profile.healthMax
	
	if Me.db.profile.charges.enable and Me.db.profile.charges.symbol:find("charge") then
		if Me.db.profile.charges.max > 8 then
			Me.db.profile.charges.max = 8;
		end
		if Me.db.profile.charges.count > 8 then
			Me.db.profile.charges.count = 8
		end
		Me.configOptionsCharges.args.chargesGroup.args.chargesMax.hidden = false
		Me.configOptionsCharges.args.chargesGroup.args.chargesMaxTwo.hidden = true
	else
		Me.configOptionsCharges.args.chargesGroup.args.chargesMax.hidden = true
		Me.configOptionsCharges.args.chargesGroup.args.chargesMaxTwo.hidden = false
	end
	
	if Me.db.profile.health > Me.db.profile.healthMax then
		Me.db.profile.health = Me.db.profile.healthMax
	end
	
	-- the first time we open the options frame, it wont go to the right page
	if interfaceOptionsNeedsInit then
		InterfaceOptionsFrame_OpenToCategory( "DiceMaster" )
		interfaceOptionsNeedsInit = nil
	end
	InterfaceOptionsFrame_OpenToCategory( "DiceMaster" )
	LibStub("AceConfigRegistry-3.0"):NotifyChange( "DiceMaster" )
end

-------------------------------------------------------------------------------
function Me.ApplyConfig( onload )
	Me.configOptionsCharges.args.chargesGroup.hidden = not Me.db.profile.charges.enable
	Me.configOptions.args.resetUses.hidden = not Me.db.profile.showUses
	Me.configOptionsCharges.args.healthGroup.args.healthCurrent.max = Me.db.profile.healthMax

	Me.ImportDM5Saved()
	
	-- bump all serials, everything is considered dirty
	Me.BumpSerial( Me.db.char, "statusSerial" )
	for i = 1, 5 do
		Me.BumpSerial( Me.db.char.traitSerials, i )
	end
	Me.Inspect_ShareStatusWithParty()
	
	Me.ApplyUiScale()
	Me.RefreshHealthbarFrame( DiceMasterChargesFrame.healthbar, Me.db.profile.health, Me.db.profile.healthMax, Me.db.profile.armor )
	Me.RefreshChargesFrame( true, true )  
	Me.TraitEditor_Refresh()
	Me.TraitEditor_UpdateInventory()
	Me.ShopFrame_Update()	
	Me.UpdatePanelTraits()
end
