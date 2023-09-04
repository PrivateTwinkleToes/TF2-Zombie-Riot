#pragma semicolon 1
#pragma newdecls required

//Handle h_TimerHazardManagement[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
static float f_WeaponDelayGiveRandom[MAXPLAYERS+1]={0.0, ...};
static int LessRandomDamage = 1;
static int Luck = 0;

void Hazard_Map_Precache()
{
	Zero(f_WeaponDelayGiveRandom);
	PrecacheSound("weapons/weapon_crit_charged_off.wav");
}

public float NPC_OnTakeDamage_Hazard(int attacker, int victim, float &damage, int weapon)
{
	float DamageMod;
	switch(i_CustomWeaponEquipLogic[weapon])
	{
		case WEAPON_HAZARD:
		{
			int RNG = GetRandomInt(1,100);
			if (RNG < 32)
			{
				DamageMod = 0.75;
			}
			else if (31 < RNG < 64)
			{
				DamageMod = 1.0;
			}
			else if (63 < RNG < 96)
			{
				DamageMod = 1.3;
			}
			else
			{
				PrintHintText(attacker,"JACKPOT!");
				DisplayCritAboveNpc(victim, attacker, true);
				DamageMod = 5.0;
			}
		}
		case WEAPON_HAZARD_UNSTABLE:
		{
			int RNG = GetRandomInt(1,100);
			if (RNG < 20)
			{
				DamageMod = 0.75;
			}
			else if (19 < RNG < 39)
			{
				DamageMod = 0.9;
			}
			else if (38 < RNG < 58)
			{
				DamageMod = 1.05;
			}
			else if (57 < RNG < 77)
			{
				DamageMod = 1.2;
			}
			else if (76 < RNG < 96)
			{
				DamageMod = 1.35;
			}
			else
			{
				PrintHintText(attacker,"JACKPOT!");
				DisplayCritAboveNpc(victim, attacker, true);
				DamageMod = 5.0;
			}
		}
		case WEAPON_HAZARD_LUNATIC:
		{
			int RNG = GetRandomInt(100,210);
			if (RNG < 201)
			{

				DamageMod = (RNG / 100.0);
			}
			else
			{
				DamageMod = GetRandomFloat(4.0,6.0);
				DisplayCritAboveNpc(victim, attacker, true);
				PrintHintText(attacker,"JACKPOT!");
			}
		}
		case WEAPON_HAZARD_CHAOS:
		{
			int RNG = GetRandomInt(100,210);
			if (RNG < 201)
			{

				DamageMod = (RNG / 100.0);
			}
			else
			{
				DamageMod = GetRandomFloat(4.0,6.0);
				DisplayCritAboveNpc(victim, attacker, true);
				PrintHintText(attacker,"JACKPOT!");
			}
		}
		case WEAPON_HAZARD_STABILIZED:
		{
			int RNG = GetRandomInt(1,100);
			if (RNG < 41)
			{
				DamageMod = 1.15;
			}
			else if (40 < RNG < 81)
			{
				DamageMod = 1.3;
			}
			else
			{
				PrintHintText(attacker,"JACKPOT!");
				DisplayCritAboveNpc(victim, attacker, true);
				DamageMod = 2.5;
			}
		}
		case WEAPON_HAZARD_DEMI:
		{
			if (Ability_Check_Cooldown(attacker, 2) >= 19.9 && Ability_Check_Cooldown(attacker, 2) < 31.0)
			{
				Luck += 3;
			}
			int RNG = GetRandomInt(1,10) + Luck;
			switch(RNG)
			{
				case 1, 2, 3, 4:
				{
					DamageMod = 1.2;
					Luck *= 0;
				}
				case 5, 6, 7, 8:
				{
					DamageMod = 1.4;
					Luck *= 0;
				}
				case 9, 10, 11, 12, 13:
				{
					DisplayCritAboveNpc(victim, attacker, true);
					DamageMod = 3.0;
					Luck *= 0;
				}
			}
		}
		case WEAPON_HAZARD_PERFECT:
		{
			if (Ability_Check_Cooldown(attacker, 2) >= 9.9 && Ability_Check_Cooldown(attacker, 2) < 21.0)
			{
				Luck += 5;
			}
			int RNG = GetRandomInt(1,10) + Luck;
			switch(RNG)
			{
				case 1, 2, 3, 4:
				{
					DamageMod = 1.2;
					Luck *= 0;
				}
				case 5, 6, 7, 8:
				{
					DamageMod = 1.4;
					Luck *= 0;
				}
				case 9, 10, 11, 12, 13, 14:
				{
					DisplayCritAboveNpc(victim, attacker, true);
					DamageMod = 3.0;
					Luck *= 0;
				}
				case 15:
				{
					PrintHintText(attacker,"J̸̨͝Ä̷̻͆Ç̸̛̮K̵̻͗þ̸̤͝Ơ̶͚̈†̸̲̍!̴̡́");
					ClientCommand(attacker, "playgamesound player/crit_received1.wav");
					DisplayCritAboveNpc(victim, attacker, true);
					DamageMod = 6.0;
					ApplyTempAttrib(weapon, 6, 0.8, 5.0);
					Luck *= 0;
				}
				default:
				{
					DamageMod = 1.1;
				}
			}
		}
		default:
		{
			//PrintToChatAll("Erorr!");
		}
	}
	return damage *= DamageMod;
}

public void Weapon_Hazard(int client, int weapon, bool crit, int slot)
{
	if(f_WeaponDelayGiveRandom[client] > GetGameTime())
		return;

	f_WeaponDelayGiveRandom[client] = GetGameTime() + 0.25;

	int viewmodelModel;
	viewmodelModel = EntRefToEntIndex(i_Viewmodel_PlayerModel[client]);
	if(!IsValidEntity(viewmodelModel))
		return;

	switch(i_CustomWeaponEquipLogic[weapon])
	{
		case WEAPON_HAZARD_LUNATIC:
		{
			ApplyTempAttrib(weapon, 6, GetRandomFloat(0.45,1.05), 0.3); //random attack speed
			int RNG = GetRandomInt(1,10);
			switch(RNG)
			{
				case 3:
				{
					if(LessRandomDamage < 0)
					{
						float flPos[3]; 
						float flAng[3];	
						int particler = ParticleEffectAt(flPos, "critical_rocket_redsparks", 2.0);
				
						GetAttachment(viewmodelModel, "effect_hand_r", flPos, flAng);

						SetParent(viewmodelModel, particler, "effect_hand_r");

						ApplyTempAttrib(weapon, 2, 0.65, 2.5);
						LessRandomDamage += 3;
					}
					else
					{
						ApplyTempAttrib(weapon, 2, 0.95, 1.0);
						LessRandomDamage += 1;
					}
					}
				case 6:
				{
					if(LessRandomDamage > 0)
					{
						float flPos[3]; 
						float flAng[3];	
						int particler = ParticleEffectAt(flPos, "critical_rocket_bluesparks", 2.0);
						GetAttachment(viewmodelModel, "effect_hand_r", flPos, flAng);
				
						SetParent(viewmodelModel, particler, "effect_hand_r");
		
						ApplyTempAttrib(weapon, 2, 1.35, 2.5);
						LessRandomDamage -= 2;
					}
					else
					{
						ApplyTempAttrib(weapon, 2, 1.05, 1.0);
						LessRandomDamage -= 1;
					}
				}
			}
		}
		case WEAPON_HAZARD_CHAOS:
		{
			ApplyTempAttrib(weapon, 6, GetRandomFloat(0.5,1.0), 0.5); //random attack speed
			int RNG = GetRandomInt(1,10); //RNG for condition
			float MaxHealth = float(SDKCall_GetMaxHealth(client));
			int flHealth = GetClientHealth(client); // :)
			switch(RNG)
			{
				case 1:
				{
				//	TF2_RemoveCondition(client, TFCond_Slowed);
					TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.25); //SPEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEED
				}
				case 2:
				{
					TF2_RemoveCondition(client, TFCond_SpeedBuffAlly); //no more SPEEEEEEEEEEEEEEEEEEED
				//	TF2_AddCondition(client, TFCond_Slowed, 0.4);
				}
				case 3:
				{
					if(LessRandomDamage < 0)
					{
						float flPos[3]; 
						float flAng[3];	
						int particler = ParticleEffectAt(flPos, "critical_rocket_redsparks", 2.0);
						GetAttachment(viewmodelModel, "effect_hand_r", flPos, flAng);
				
						SetParent(viewmodelModel, particler, "effect_hand_r");
		
						ApplyTempAttrib(weapon, 2, 0.65, 2.5);
						LessRandomDamage += 3;
					}
					else
					{
						ApplyTempAttrib(weapon, 2, 0.95, 1.0);
						LessRandomDamage += 1;
					}
				}
				case 4:
				{
					if(LessRandomDamage > 0)
					{
						float flPos[3]; 
						float flAng[3];	
						int particler = ParticleEffectAt(flPos, "critical_rocket_bluesparks", 2.0);
						GetAttachment(viewmodelModel, "effect_hand_r", flPos, flAng);
				
						SetParent(viewmodelModel, particler, "effect_hand_r");
		
						ApplyTempAttrib(weapon, 2, 1.35, 2.5);
						LessRandomDamage -= 2;
					}
					else
					{
						ApplyTempAttrib(weapon, 2, 1.05, 1.0);
						LessRandomDamage -= 1;
					}
				}
				case 5:
				{
					TF2_RemoveCondition(client, TFCond_MarkedForDeathSilent);
					TF2_AddCondition(client, TFCond_DefenseBuffed, 5.0);
				}
				case 6:
				{
					TF2_RemoveCondition(client, TFCond_DefenseBuffed);
					TF2_AddCondition(client, TFCond_MarkedForDeathSilent, 5.0);
				}
				case 7:
				{
					StartHealingTimer(client, 0.1,  MaxHealth * 0.003, 5);
				}
				case 8:
				{
					if (flHealth < (MaxHealth * 0.05))
					{
						StartHealingTimer(client, 0.1,  MaxHealth * 0.003, 5);
					}
					else
					{
						StartHealingTimer(client, 0.1, 	MaxHealth * -0.002, 5);
					}
				}
				case 9:
				{
					float flPos[3]; 
					float flAng[3];	
					int particler = ParticleEffectAt(flPos, "rocketpack_exhaust", 2.5);
					GetAttachment(viewmodelModel, "effect_hand_r", flPos, flAng);
			
					SetParent(viewmodelModel, particler, "effect_hand_r");
	
					ApplyTempAttrib(weapon, 2, 1.5, 3.0);
					ApplyTempAttrib(weapon, 6, 1.5, 3.0);
					LessRandomDamage += 2;
				}
				default:
				{
					return;
				}
			}
		}
		default:
		{
			PrintToChatAll("Error!");
			return;
		}
	}
}

public void Hazard_Luck(int client, int weapon, bool crit, int slot)
{
	int viewmodelModel;
	viewmodelModel = EntRefToEntIndex(i_Viewmodel_PlayerModel[client]);
	if(!IsValidEntity(viewmodelModel))
		return;

	if (Ability_Check_Cooldown(client, slot) < 0.0)
	{
		Rogue_OnAbilityUse(weapon);
		Ability_Apply_Cooldown(client, slot, 30.0);
		EmitSoundToAll("weapons/weapon_crit_charged_off.wav", client);
		float flPos[3]; 
		float flAng[3];	
		GetAttachment(viewmodelModel, "effect_hand_r", flPos, flAng);

		int particler = ParticleEffectAt(flPos, "halloween_rockettrail", 10.0);
				
		SetParent(viewmodelModel, particler, "effect_hand_r");
		
	}
	else
	{
		float Ability_CD = Ability_Check_Cooldown(client, slot);
		
		if(Ability_CD <= 0.0)
		{
			Ability_CD = 0.0;
		}
			
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);
	}
}

public void Hazard_Luck_Pap(int client, int weapon, bool crit, int slot)
{
	int viewmodelModel;
	viewmodelModel = EntRefToEntIndex(i_Viewmodel_PlayerModel[client]);
	if(!IsValidEntity(viewmodelModel))
		return;
		
	if (Ability_Check_Cooldown(client, slot) < 0.0)
	{
		Rogue_OnAbilityUse(weapon);
		Ability_Apply_Cooldown(client, slot, 20.0);
		EmitSoundToAll("weapons/weapon_crit_charged_off.wav", client);
		float flPos[3]; 
		float flAng[3];	
		int particler = ParticleEffectAt(flPos, "halloween_rockettrail", 10.0);
		GetAttachment(viewmodelModel, "effect_hand_r", flPos, flAng);
				
		SetParent(viewmodelModel, particler, "effect_hand_r");
	}
	else
	{
		float Ability_CD = Ability_Check_Cooldown(client, slot);
		
		if(Ability_CD <= 0.0)
		{
			Ability_CD = 0.0;
		}
			
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client,  SyncHud_Notifaction, "%t", "Ability has cooldown", Ability_CD);
	}
}

/*public Action Timer_Management_Hazard(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	if(IsValidClient(client))
	{
		if (IsClientInGame(client))
		{
			Kill_Timer_Hazard(client);
		}
		else
			Kill_Timer_Hazard(client);
	}
	else
		Kill_Timer_Hazard(client);
		
	return Plugin_Continue;
}

public void Kill_Timer_Hazard(int client)
{
	if (h_TimerHazardManagement[client] != INVALID_HANDLE)
	{
		KillTimer(h_TimerHazardManagement[client]);
		h_TimerHazardManagement[client] = INVALID_HANDLE;
	}
}

public void Enable_Hazard(int client, int weapon) 
{
	if (h_TimerHazardManagement[client] != INVALID_HANDLE)
	{
		//This timer already exists.
		if(i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_UNSTABLE || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_LUNATIC || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_CHAOS || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_STABILIZED || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_DEMI || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_PERFECT) 
		{
			//Is the weapon it again?
			//Yes?
			KillTimer(h_TimerHazardManagement[client]);
			h_TimerHazardManagement[client] = INVALID_HANDLE;
			DataPack pack;
			h_TimerHazardManagement[client] = CreateDataTimer(0.1, Timer_Management_Hazard, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(client);
			pack.WriteCell(EntIndexToEntRef(weapon));
		}
		return;
	}
		
	if(i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_UNSTABLE || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_LUNATIC || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_CHAOS || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_STABILIZED || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_DEMI || i_CustomWeaponEquipLogic[weapon] == WEAPON_HAZARD_PERFECT)
	{
		DataPack pack;
		h_TimerHazardManagement[client] = CreateDataTimer(0.1, Timer_Management_Hazard, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(client);
		pack.WriteCell(EntIndexToEntRef(weapon));
	}
}
*/