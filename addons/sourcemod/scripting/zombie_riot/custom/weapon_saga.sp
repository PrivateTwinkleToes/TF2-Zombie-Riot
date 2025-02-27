#define SAGA_ABILITY_1	"npc/waste_scanner/grenade_fire.wav"
#define SAGA_ABILITY_2	"npc/waste_scanner/grenade_fire.wav"
#define SAGA_ABILITY_3	"npc/waste_scanner/grenade_fire.wav"

//NA GO GOHOM
static Handle WeaponTimer[MAXTF2PLAYERS];
static int WeaponRef[MAXTF2PLAYERS];
static int WeaponCharge[MAXTF2PLAYERS];
static float SagaCrippled[MAXENTITIES + 1];
static bool SagaRegen[MAXENTITIES];

static const char g_MeleeHitSounds[][] =
{
	"weapons/samurai/tf_katana_slice_01.wav",
	"weapons/samurai/tf_katana_slice_02.wav",
	"weapons/samurai/tf_katana_slice_03.wav",
};

void Saga_MapStart()
{
	PrecacheSound(SAGA_ABILITY_1);
	PrecacheSound(SAGA_ABILITY_2);
	PrecacheSound(SAGA_ABILITY_3);
	Zero(SagaCrippled);
	Zero(WeaponCharge);
	Zero(SagaRegen);
	for (int i = 0; i < (sizeof(g_MeleeHitSounds));	i++) { PrecacheSound(g_MeleeHitSounds[i]);	}
}

void Saga_EntityCreated(int entity)
{
	SagaCrippled[entity] = 0.0;
}

bool Saga_EnemyDoomed(int entity)
{
	return view_as<bool>(SagaCrippled[entity]);
}

bool Saga_RegenHealth(int entity)
{
	return SagaRegen[entity];
}

void Saga_DeadEffects(int victim, int attacker, int weapon)
{
	if(SagaCrippled[victim])
		Saga_ChargeReduction(attacker, weapon, SagaCrippled[victim]);
}

bool Saga_IsChargeWeapon(int client, int weapon)
{
	if(!IsValidEntity(weapon))
		return false;

	if(f_UberOnHitWeapon[weapon])
		return true;
	
	if(Passanger_HasCharge(client))
		return true;
	
	if(Gladiia_HasCharge(client, weapon))
		return true;
	
	if(WeaponTimer[client] && EntRefToEntIndex(WeaponRef[client]) == weapon)
		return true;
	
	for(int i = 1; i < 4; i++)
	{
		float cooldown = Ability_Check_Cooldown(client, i, weapon);
		if(cooldown > 0.0)
			return true;
	}

	return false;
}

void Saga_ChargeReduction(int client, int weapon, float time)
{
	Passanger_ChargeReduced(client, time);
	Gladiia_ChargeReduction(client, weapon, time);

	if(WeaponTimer[client] && EntRefToEntIndex(WeaponRef[client]) == weapon)
	{
		//WeaponCharge[client] += RoundFloat(time) - 1;
		TriggerTimer(WeaponTimer[client], false);
	}
	
	for(int i = 1; i < 4; i++)
	{
		float cooldown = Ability_Check_Cooldown(client, i, weapon);
		if(cooldown > 0.0)
		{
			Ability_Apply_Cooldown(client, i, cooldown - time, weapon);
			break;
		}
	}
}

void Saga_Enable(int client, int weapon)
{
	SagaRegen[client] = false;

	if(i_CustomWeaponEquipLogic[weapon] == 19)
	{
		WeaponRef[client] = EntIndexToEntRef(weapon);
		delete WeaponTimer[client];

		float value = Attributes_Get(weapon, 861, -1.0);
		if(value == -1.0)
		{
			// Elite 0 Special 1
			WeaponTimer[client] = CreateTimer(3.5, Saga_Timer1, client, TIMER_REPEAT);
		}
		else if(value == 0.0)
		{
			// Elite 1 Special 2
			WeaponTimer[client] = CreateTimer(1.0, Saga_Timer2, client, TIMER_REPEAT);
		}
		else
		{
			// Elite 1 Special 3
			WeaponTimer[client] = CreateTimer(1.0, Saga_Timer3, client, TIMER_REPEAT);
		}
	}
}

public Action Saga_Timer1(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		int weapon = EntRefToEntIndex(WeaponRef[client]);
		if(weapon != INVALID_ENT_REFERENCE)
		{
			if(weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
			{
				int amount = 1;
				/*
				 + (WeaponCharge[client] * 7 / 2);

				if(amount > 1)
					WeaponCharge[client] -= amount + 1;
				
				if(amount < 0)
					amount = 1; //dont give shit.
				*/
				
				CashRecievedNonWave[client] += amount;
				CashSpent[client] -= amount;
			}
			
			return Plugin_Continue;
		}
	}

	WeaponTimer[client] = null;
	return Plugin_Stop;
}

public Action Saga_Timer2(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		int weapon = EntRefToEntIndex(WeaponRef[client]);
		if(weapon != INVALID_ENT_REFERENCE)
		{
			if(weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
			{
				if(++WeaponCharge[client] > 32)
					WeaponCharge[client] = 32;
				
				PrintHintText(client, "Cleansing Evil [%d / 2] {%ds}", WeaponCharge[client] / 16, 16 - (WeaponCharge[client] % 16));
				StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
			}

			return Plugin_Continue;
		}
	}

	WeaponTimer[client] = null;
	return Plugin_Stop;
}

public Action Saga_Timer3(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		int weapon = EntRefToEntIndex(WeaponRef[client]);
		if(weapon != INVALID_ENT_REFERENCE)
		{
			if(weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
			{
				SagaRegen[client] = true;
				if(++WeaponCharge[client] > 39)
					WeaponCharge[client] = 39;
				
				PrintHintText(client, "Cleansing Evil [%d / 3] {%ds}", WeaponCharge[client] / 13, 13 - (WeaponCharge[client] % 13));
				StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
			}
			else
			{
				SagaRegen[client] = false;
			}

			return Plugin_Continue;
		}
	}

	SagaRegen[client] = false;
	WeaponTimer[client] = null;
	return Plugin_Stop;
}

public void Weapon_SagaE1_M2(int client, int weapon, bool crit, int slot)
{
	Weapon_Saga_M2(client, weapon, false);
}

public void Weapon_SagaE2_M2(int client, int weapon, bool crit, int slot)
{
	Weapon_Saga_M2(client, weapon, true);
}

static void Weapon_Saga_M2(int client, int weapon, bool mastery)
{
	int cost = mastery ? 13 : 16;
	if(CvarInfiniteCash.BoolValue)
	{
		WeaponCharge[client] = 999;
	}
	if(WeaponCharge[client] < cost)
	{
		ClientCommand(client, "playgamesound items/medshotno1.wav");
		SetDefaultHudPosition(client);
		SetGlobalTransTarget(client);
		ShowSyncHudText(client, SyncHud_Notifaction, "%t", "Ability has cooldown", float(cost - WeaponCharge[client]));
	}
	else
	{
		Rogue_OnAbilityUse(weapon);
		MakePlayerGiveResponseVoice(client, 4); //haha!
		WeaponCharge[client] -= cost + 1;
		CashRecievedNonWave[client] += 4;
		CashSpent[client] -= 4;
		
		float damage = mastery ? 260.0 : 208.0;	// 400%, 320%
		damage *= Attributes_Get(weapon, 2, 1.0);
		
		int value = i_ExplosiveProjectileHexArray[client];
		i_ExplosiveProjectileHexArray[client] = EP_DEALS_CLUB_DAMAGE;

		float UserLoc[3];
		GetClientAbsOrigin(client, UserLoc);

		float Range = 400.0;
		spawnRing_Vectors(UserLoc, 0.0, 0.0, 0.0, 5.0, "materials/sprites/laserbeam.vmt", 255, 0, 0, 200, 1, 0.25, 12.0, 6.1, 1, Range * 2.0);	
		spawnRing_Vectors(UserLoc, Range * 2.0, 0.0, 0.0, 5.0, "materials/sprites/laserbeam.vmt", 255, 0, 0, 200, 1, 0.25, 12.0, 6.1, 1, 0.0);	
		b_LagCompNPC_No_Layers = true;
		StartLagCompensation_Base_Boss(client);				
		Explode_Logic_Custom(damage, client, client, weapon, _, Range, 1.0, 0.0, false, 6,_,_,SagaCutFirst);
		FinishLagCompensation_Base_boss();
		
		i_ExplosiveProjectileHexArray[client] = value;
		TF2_AddCondition(client, TFCond_DefenseBuffed, 1.0);

		CreateTimer(0.2, Saga_DelayedExplode, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

		int rand = GetURandomInt() % 3;
		EmitSoundToAll(rand == 0 ? SAGA_ABILITY_1 : (rand == 1 ? SAGA_ABILITY_2 : SAGA_ABILITY_3), client, SNDCHAN_AUTO, 75_,_,0.6);

		TriggerTimer(WeaponTimer[client], true);
	}
}

public Action Saga_DelayedExplode(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		int weapon = EntRefToEntIndex(WeaponRef[client]);
		if(weapon != INVALID_ENT_REFERENCE)
		{
			float damage = 0.1;
			damage *= Attributes_Get(weapon, 2, 1.0);
			
			int value = i_ExplosiveProjectileHexArray[client];
			i_ExplosiveProjectileHexArray[client] = EP_DEALS_SLASH_DAMAGE;

			b_LagCompNPC_No_Layers = true;
			StartLagCompensation_Base_Boss(client);						
			Explode_Logic_Custom(damage, client, client, weapon, _, 400.0, 1.0, 0.0, false, 99,_,_,SagaCutLast);
			FinishLagCompensation_Base_boss();			
			i_ExplosiveProjectileHexArray[client] = value;
		}
	}
	return Plugin_Continue;
}

void Saga_OnTakeDamage(int victim, int &attacker, float &damage, int &weapon)
{
	if(SagaCrippled[victim])
	{
		damage = 0.0;
	}
	else if(RoundToFloor(damage) >= GetEntProp(victim, Prop_Data, "m_iHealth"))
	{
		damage = float(GetEntProp(victim, Prop_Data, "m_iHealth") - 1);

		SagaCrippled[victim] = Attributes_Get(weapon, 861, -1.0) == -1.0 ? 1.0 : 2.0;
		CreateTimer(10.0, Saga_ExcuteTarget, EntIndexToEntRef(victim), TIMER_FLAG_NO_MAPCHANGE);
		FreezeNpcInTime(victim, 10.2);
		SetEntityRenderMode(victim, RENDER_TRANSCOLOR, false, 1, false, true);
		SetEntityRenderColor(victim, 255, 65, 65, 125, false, false, true);
		b_ThisEntityIgnoredByOtherNpcsAggro[victim] = true;
		Change_Npc_Collision(victim, 3);
		SetEntityCollisionGroup(victim, 17);
		b_DoNotUnStuck[victim] = true;
		CClotBody npc = view_as<CClotBody>(victim);
		Npc_DebuffWorldTextUpdate(npc);
		Attributes_OnKill(attacker, weapon);
		//so using this sword against a raid doesnt result in an auto lose.
		if(EntRefToEntIndex(RaidBossActive) == victim)
		{
			RaidModeTime += 11.0;
		}
	}
}

public Action Saga_ExcuteTarget(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
		SDKHooks_TakeDamage(entity, 0, 0, 9999.9, DMG_SLASH);
	
	return Plugin_Continue;
}



void SagaCutFirst(int entity, int victim, float damage, int weapon)
{
	FreezeNpcInTime(victim, 0.2);
	float Range = 150.0;
	float Pos[3];
	GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", Pos);
	spawnRing_Vectors(Pos, Range * 2.0, 0.0, 0.0, 5.0, "materials/sprites/laserbeam.vmt", 255, 0, 0, 200, 1, 0.25, 12.0, 6.1, 1, 0.0);	
}


void SagaCutLast(int entity, int victim, float damage, int weapon)
{
	if(SagaCrippled[victim])
	{
		float VicLoc[3];
		VicLoc = WorldSpaceCenter(victim);

		float Pos1[3];
		float Pos2[3];
		float PosRand[3];

		Pos1 = VicLoc;
		Pos2 = VicLoc;

		PosRand[2] = GetRandomFloat(50.0,75.0);
		PosRand[0] = GetRandomFloat(-25.0,25.0);
		PosRand[1] = GetRandomFloat(-25.0,25.0);

		if(b_IsGiant[victim])
		{
			PosRand[0] *= 1.5;
			PosRand[1] *= 1.5;
			PosRand[2] *= 1.5;
		}

		Pos1[0] += PosRand[0];
		Pos1[1] += PosRand[1];
		Pos1[2] += PosRand[2];

		Pos2[0] -= PosRand[0];
		Pos2[1] -= PosRand[1];
		Pos2[2] -= PosRand[2];

		//get random pos offset for cool slash effect cus i can.
		
		int particle = ParticleEffectAt(Pos1, "raygun_projectile_red_crit", 0.3);

		DataPack pack = new DataPack();
		pack.WriteCell(EntIndexToEntRef(particle));
		pack.WriteFloat(Pos2[0]);
		pack.WriteFloat(Pos2[1]);
		pack.WriteFloat(Pos2[2]);
		RequestFrames(TeleportParticleArk, 10,pack);
		

	//	TE_SetupBeamPoints(Pos1, Pos2, ShortTeleportLaserIndex, 0, 0, 0, 0.25, 10.0, 10.0, 0, 1.0, {255,0,0,200}, 3);
	//	TE_SendToAll(0.0);


		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], 0, SNDCHAN_AUTO, 90, _,_,GetRandomInt(80,110),-1,VicLoc);
	
		SDKHooks_TakeDamage(victim, weapon, entity, 10.0, DMG_SLASH, weapon, _, _, _, _);
	}
}

void SagaAttackBeforeSwing(int client)
{
	SagaCrippled[client] = 1.0;
}
void SagaAttackAfterSwing(int client)
{
	SagaCrippled[client] = 0.0;
}