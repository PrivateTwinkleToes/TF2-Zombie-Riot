#pragma semicolon 1
#pragma newdecls required

static char g_DeathSounds[][] =
{
	"vo/sniper_paincrticialdeath01.mp3",
	"vo/sniper_paincrticialdeath02.mp3",
	"vo/sniper_paincrticialdeath03.mp3"
};

static char g_HurtSounds[][] =
{
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
	"npc/zombie/zombie_pain6.wav",
};

static char g_MeleeHitSounds[][] =
{
	"npc/vort/foot_hit.wav",
};

static char g_MeleeAttackSounds[][] =
{
	"npc/zombie_poison/pz_warn1.wav",
	"npc/zombie_poison/pz_warn2.wav",
};

static char g_RangedAttackSounds[][] =
{
	"npc/zombie_poison/pz_throw2.wav",
	"npc/zombie_poison/pz_throw3.wav",
};

static char g_RangedSpecialAttackSounds[][] =
{
	"npc/fast_zombie/leap1.wav",
};

static char g_BoomSounds[][] =
{
	"npc/strider/striderx_die1.wav"
};

static char g_SMGAttackSounds[][] =
{
	"weapons/doom_sniper_smg.wav"
};

static char g_BuffSounds[][] =
{
	"player/invuln_off_vaccinator.wav"
};

static char g_AngerSounds[][] =
{
	"mvm/mvm_tank_end.wav",
};

static char g_HappySounds[][] =
{
	"vo/taunts/sniper/sniper_taunt_admire_02.mp3",
	"vo/compmode/cm_sniper_pregamefirst_6s_05.mp3",
	"vo/compmode/cm_sniper_matchwon_02.mp3",
	"vo/compmode/cm_sniper_matchwon_07.mp3",
	"vo/compmode/cm_sniper_matchwon_10.mp3",
	"vo/compmode/cm_sniper_matchwon_11.mp3",
	"vo/compmode/cm_sniper_matchwon_14.mp3"
};


int i_NemesisEntitiesHitAoeSwing[MAXENTITIES];	//Who got hit
float f_NemesisEnemyHitCooldown[MAXENTITIES];

float f_NemesisCauseInfectionBox[MAXENTITIES];
float f_NemesisHitBoxStart[MAXENTITIES];
float f_NemesisHitBoxEnd[MAXENTITIES];
static int i_GrabbedThis[MAXENTITIES];
static float fl_RegainWalkAnim[MAXENTITIES];
static float fl_OverrideWalkDest[MAXENTITIES];
static float fl_StopDodge[MAXENTITIES];
static float fl_StopDodgeCD[MAXENTITIES];

static float f3_LastValidPosition[MAXENTITIES][3]; //Before grab to be exact
static int i_TankAntiStuck[MAXENTITIES];
static int i_GunMode[MAXENTITIES];
static int i_GunAmmo[MAXENTITIES];
float f_NemesisImmuneToInfection[MAXENTITIES];
float f_NemesisSpecialDeathAnimation[MAXENTITIES];
float f_NemesisRandomInfectionCycle[MAXENTITIES];
#define NEMESIS_MODEL "models/zombie_riot/bosses/nemesis_ft1_v6.mdl"
#define INFECTION_MODEL "models/weapons/w_bugbait.mdl"
#define INFECTION_RANGE 150.0
#define INFECTION_DELAY 0.8

void RaidbossNemesis_OnMapStart()
{
	for (int i = 0; i < (sizeof(g_DeathSounds));       i++) { PrecacheSound(g_DeathSounds[i]);       }
	for (int i = 0; i < (sizeof(g_HurtSounds));        i++) { PrecacheSound(g_HurtSounds[i]);        }
	for (int i = 0; i < (sizeof(g_MeleeHitSounds));    i++) { PrecacheSound(g_MeleeHitSounds[i]);    }
	for (int i = 0; i < (sizeof(g_MeleeAttackSounds));    i++) { PrecacheSound(g_MeleeAttackSounds[i]);    }
	for (int i = 0; i < (sizeof(g_RangedAttackSounds));   i++) { PrecacheSound(g_RangedAttackSounds[i]);   }
	for (int i = 0; i < (sizeof(g_AngerSounds));   i++) { PrecacheSound(g_AngerSounds[i]);   }
	for (int i = 0; i < (sizeof(g_BoomSounds));   i++) { PrecacheSound(g_BoomSounds[i]);   }
	PrecacheModel(INFECTION_MODEL);
	PrecacheModel(NEMESIS_MODEL);
	PrecacheSound("weapons/cow_mangler_explode.wav");
	PrecacheSoundCustom("#zombie_riot/320_now.mp3");
}

methodmap RaidbossNemesis < CClotBody
{
	public void PlayHurtSound()
	{
		int sound = GetRandomInt(0, sizeof(g_HurtSounds) - 1);

		EmitSoundToAll(g_HurtSounds[sound], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 65);
		this.m_flNextHurtSound = GetGameTime(this.index) + GetRandomFloat(0.6, 1.6);
	}
	public void PlayDeathSound()
	{
		int sound = GetRandomInt(0, sizeof(g_DeathSounds) - 1);
		
		EmitSoundToAll(g_DeathSounds[sound], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayMeleeSound()
	{
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 80);
	}
	public void PlaySMGSound()
	{
		EmitSoundToAll(g_SMGAttackSounds[GetRandomInt(0, sizeof(g_SMGAttackSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayRangedSound()
	{
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME,65);
	}
	public void PlayRangedSpecialSound()
	{
		EmitSoundToAll(g_RangedSpecialAttackSounds[GetRandomInt(0, sizeof(g_RangedSpecialAttackSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 80);
		EmitSoundToAll(g_RangedSpecialAttackSounds[GetRandomInt(0, sizeof(g_RangedSpecialAttackSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 80);
	}
	public void PlayBoomSound()
	{
		EmitSoundToAll(g_BoomSounds[GetRandomInt(0, sizeof(g_BoomSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 60);
	}
	public void PlayAngerSound()
	{
		int sound = GetRandomInt(0, sizeof(g_AngerSounds) - 1);
		EmitSoundToAll(g_AngerSounds[sound], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayRevengeSound()
	{
		char buffer[64];
		FormatEx(buffer, sizeof(buffer), "vo/sniper_revenge%02d.mp3", (GetURandomInt() % 25) + 1);
		EmitSoundToAll(buffer, this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayHappySound()
	{
		EmitSoundToAll(g_HappySounds[GetRandomInt(0, sizeof(g_HappySounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayMeleeHitSound()
	{
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME, 80);
	}
	public void PlayBuffSound()
	{
		EmitSoundToAll(g_BuffSounds[GetRandomInt(0, sizeof(g_BuffSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public RaidbossNemesis(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		RaidbossNemesis npc = view_as<RaidbossNemesis>(CClotBody(vecPos, vecAng, NEMESIS_MODEL, "1.75", "20000000", ally, false, true, true,true)); //giant!
		
		//model originally from Roach, https://steamcommunity.com/sharedfiles/filedetails/?id=2053348633&searchtext=nemesis

		//wave 75 xeno raidboss,should be extreamly hard, but still fair, that will be hard to do.

		i_NpcInternalId[npc.index] = XENO_RAIDBOSS_NEMESIS;
		
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");
		
		int iActivity = npc.LookupActivity("ACT_FT2_WALK");
		if(iActivity > 0) npc.StartActivity(iActivity);
		
		SDKHook(npc.index, SDKHook_Think, RaidbossNemesis_ClotThink);
		SDKHook(npc.index, SDKHook_OnTakeDamage, RaidbossNemesis_ClotDamaged);
		SDKHook(npc.index, SDKHook_OnTakeDamagePost, RaidbossNemesis_OnTakeDamagePost);
		RaidBossActive = EntIndexToEntRef(npc.index);
		RaidModeTime = GetGameTime(npc.index) + 200.0;
		npc.m_flMeleeArmor = 1.5; 		//Melee should be rewarded for trying to face this monster

		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;	
		npc.m_iNpcStepVariation = STEPTYPE_TANK;

		EmitSoundToAll("npc/zombie_poison/pz_alert1.wav", _, _, _, _, 1.0);	
		EmitSoundToAll("npc/zombie_poison/pz_alert1.wav", _, _, _, _, 1.0);	

		for(int client_check=1; client_check<=MaxClients; client_check++)
		{
			if(IsClientInGame(client_check) && !IsFakeClient(client_check))
			{
				LookAtTarget(client_check, npc.index);
				SetGlobalTransTarget(client_check);
				ShowGameText(client_check, "item_armor", 1, "%t", "Nemesis Arrived.");
			}
		}

		Music_SetRaidMusic("#zombie_riot/320_now.mp3", 200, true, 1.0);
		RaidModeScaling = 9999999.99;
		Format(WhatDifficultySetting, sizeof(WhatDifficultySetting), "%s", "??????????????????????????????????");
		npc.m_bThisNpcIsABoss = true;
		npc.Anger = false;
		npc.m_flSpeed = 300.0;
		if(npc.Anger)
			npc.m_flSpeed = 350.0;

		npc.m_iTarget = 0;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_bDissapearOnDeath = true;
		Zero(f_NemesisEnemyHitCooldown);
		npc.m_flNextMeleeAttack = 0.0;
		npc.m_flAttackHappens = 0.0;
		i_GrabbedThis[npc.index] = -1;
		fl_RegainWalkAnim[npc.index] = 0.0;
		npc.m_flNextRangedAttack = GetGameTime(npc.index) + 15.0;
		f_NemesisSpecialDeathAnimation[npc.index] = 0.0;
		f_NemesisRandomInfectionCycle[npc.index] = GetGameTime(npc.index) + 10.0;
		Zero(f_NemesisImmuneToInfection);

		npc.m_flNextRangedSpecialAttack = GetGameTime(npc.index) + GetRandomFloat(45.0, 60.0);
		npc.m_flNextRangedSpecialAttackHappens = 0.0;
		i_GunMode[npc.index] = 0;
		i_GunAmmo[npc.index] = 0;
		
		Citizen_MiniBossSpawn(npc.index);
		npc.StartPathing();
		return npc;
	}
}

public void RaidbossNemesis_ClotThink(int iNPC)
{
	RaidbossNemesis npc = view_as<RaidbossNemesis>(iNPC);
	
	float gameTime = GetGameTime(npc.index);
	
	if(RaidModeTime < GetGameTime())
	{
		int entity = CreateEntityByName("game_round_win"); //You loose.
		DispatchKeyValue(entity, "force_map_reset", "1");
		SetEntProp(entity, Prop_Data, "m_iTeamNum", TFTeam_Blue);
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "RoundWin");
		Music_RoundEnd(entity);
		RaidBossActive = INVALID_ENT_REFERENCE;
		SDKUnhook(npc.index, SDKHook_Think, RaidbossNemesis_ClotThink);
	}

	if(npc.m_flNextDelayTime > GetGameTime(npc.index))
	{
		return;
	}

	npc.Update();

	if(npc.m_blPlayHurtAnimation)
	{
		npc.PlayHurtSound();
		npc.m_blPlayHurtAnimation = false;
	}
	
	if(f_NemesisSpecialDeathAnimation[npc.index])
	{
		npc.m_flMeleeArmor = 0.5;
		npc.m_flRangedArmor = 0.5;

		int HealByThis = GetEntProp(npc.index, Prop_Data, "m_iMaxHealth") / 4000;
		SetEntProp(npc.index, Prop_Data, "m_iHealth", GetEntProp(npc.index, Prop_Data, "m_iHealth") + HealByThis);
		if(GetEntProp(npc.index, Prop_Data, "m_iHealth") >= GetEntProp(npc.index, Prop_Data, "m_iMaxHealth"))
		{
			SetEntProp(npc.index, Prop_Data, "m_iHealth", GetEntProp(npc.index, Prop_Data, "m_iMaxHealth"));
		}

		if(f_NemesisSpecialDeathAnimation[npc.index] + 0.1 > GetGameTime(npc.index))
		{
			if(npc.m_iChanged_WalkCycle != 20) 	
			{
				PF_StopPathing(npc.index);
				npc.m_bisWalking = false;
				npc.m_bPathing = false;
				npc.m_flSpeed = 0.0;
				int iActivity = npc.LookupActivity("ACT_FT_FLINCH");
				if(iActivity > 0) npc.StartActivity(iActivity);
				npc.m_iChanged_WalkCycle = 20;
			}
		}
		if(f_NemesisSpecialDeathAnimation[npc.index] + 3.0 > GetGameTime(npc.index))
		{
			if(npc.m_iChanged_WalkCycle != 12) 	
			{
				int iActivity = npc.LookupActivity("ACT_FT_DOWN_1");
				if(iActivity > 0) npc.StartActivity(iActivity);
				npc.m_iChanged_WalkCycle = 12;
			}
		}
		else if(f_NemesisSpecialDeathAnimation[npc.index] + 14.0 > GetGameTime(npc.index))
		{
			if(npc.m_iChanged_WalkCycle != 13) 	
			{
				int iActivity = npc.LookupActivity("ACT_FT_DOWN_2");
				if(iActivity > 0) npc.StartActivity(iActivity);
				npc.m_iChanged_WalkCycle = 13;
			}
		}
		else if(f_NemesisSpecialDeathAnimation[npc.index] + 15.0 > GetGameTime(npc.index))
		{
			if(npc.m_iChanged_WalkCycle != 14) 	
			{
				int iActivity = npc.LookupActivity("ACT_FT_DOWN_3");
				if(iActivity > 0) npc.StartActivity(iActivity);
				npc.m_iChanged_WalkCycle = 14;
			}
		}
		else if(f_NemesisSpecialDeathAnimation[npc.index] + 16.0 > GetGameTime(npc.index))
		{
			f_NemesisSpecialDeathAnimation[npc.index] = 0.0;
			if(npc.m_iChanged_WalkCycle != 10) 	
			{
				int iActivity = npc.LookupActivity("ACT_FT_WALK");
				if(iActivity > 0) npc.StartActivity(iActivity);
				npc.m_iChanged_WalkCycle = 10;
				npc.m_bisWalking = true;
				npc.m_flSpeed = 50.0;
				if(npc.Anger)
					npc.m_flSpeed = 100.0;

				npc.StartPathing();
				f_NpcTurnPenalty[npc.index] = 1.0;
				if(IsValidEntity(npc.m_iWearable1))
				{
					RemoveEntity(npc.m_iWearable1);
				}
				npc.m_iWearable1 = npc.EquipItem("weapon_bone", "models/weapons/c_models/c_minigun/c_minigun.mdl");
				SetVariantString("1.0");
				AcceptEntityInput(npc.m_iWearable1, "SetModelScale");
			}	
		}
		return;
	}
	else
	{
		npc.m_flMeleeArmor = 1.5; 		//Melee should be rewarded for trying to face this monster
	}
	if(npc.m_flDoingAnimation < gameTime && i_GunMode[npc.index] == 0)
	{
		Nemesis_TryDodgeAttack(npc.index);
	}
	
	if(f_NemesisRandomInfectionCycle[npc.index] < GetGameTime(npc.index))
	{
		f_NemesisRandomInfectionCycle[npc.index] = GetGameTime(npc.index) + 10.0;
		float flPos[3]; // original
		float flAng[3]; // original
		npc.GetAttachment("RightHand", flPos, flAng);
		Nemesis_DoInfectionThrow(npc.index, 5, flPos);
		ParticleEffectAt(flPos, "duck_collect_blood_green", 1.0);
	}

	if(fl_StopDodge[npc.index])
	{
		if(fl_StopDodge[npc.index] < GetGameTime(npc.index))
		{
			b_IgnoredByPlayerProjectiles[npc.index] = false;
			int iActivity = npc.LookupActivity("ACT_FT_RAISE");
			if(iActivity > 0) npc.StartActivity(iActivity);
			npc.m_iChanged_WalkCycle = 9;
			npc.m_bisWalking = false;
			npc.m_bAllowBackWalking = true;
			npc.m_flSpeed = 0.0;
			PF_StopPathing(npc.index);
			fl_StopDodge[npc.index] = 0.0;

			i_GunMode[npc.index] = 1;
			i_GunAmmo[npc.index] = 300;

			npc.m_iWearable1 = npc.EquipItem("weapon_bone", "models/weapons/c_models/c_minigun/c_minigun.mdl");
			SetVariantString("1.0");
			AcceptEntityInput(npc.m_iWearable1, "SetModelScale");
			f_NpcTurnPenalty[npc.index] = 1.0;

			return; //just to be sure.
		}
	}
	if(f_NemesisCauseInfectionBox[npc.index])
	{
		if(f_NemesisCauseInfectionBox[npc.index] < GetGameTime(npc.index))
		{
			float flPos[3]; // original
			float flAng[3]; // original
			npc.GetAttachment("RightHand", flPos, flAng);
			Nemesis_DoInfectionThrow(npc.index, 10, flPos);
			ParticleEffectAt(flPos, "duck_collect_blood_green", 1.0);
			f_NemesisCauseInfectionBox[npc.index] = 0.0;
		}
	}

	if(i_GunAmmo[npc.index] < 0 && i_GunMode[npc.index] == 1)
	{
		if(npc.m_iChanged_WalkCycle != 11) 	
		{
			int iActivity = npc.LookupActivity("ACT_FT_LOWER");
			if(iActivity > 0) npc.StartActivity(iActivity);
			npc.m_iChanged_WalkCycle = 11;
			npc.m_bisWalking = false;
			npc.m_bAllowBackWalking = false;
			npc.m_flSpeed = 0.0;
			PF_StopPathing(npc.index);
			i_GunMode[npc.index] = 0;
			fl_RegainWalkAnim[npc.index] = gameTime + 1.5;
			npc.m_flDoingAnimation = gameTime + 1.55;
			f_NpcTurnPenalty[npc.index] = 1.0;
		}
	}

	if(fl_OverrideWalkDest[npc.index] > gameTime)
	{
		return;
	}

	if(npc.m_flGetClosestTargetTime < gameTime)
	{
		if(	i_GunMode[npc.index] != 0)
		{
			npc.m_iTarget = GetClosestTarget(npc.index,_,_,_,_,_,_,true);
			if(npc.m_iTarget == -1)
			{
				npc.m_iTarget = GetClosestTarget(npc.index);
			}
		}
		else
		{
			npc.m_iTarget = GetClosestTarget(npc.index);
		}
		npc.m_flGetClosestTargetTime = GetGameTime(npc.index) + 1.0;
	}
	if(fl_RegainWalkAnim[npc.index])
	{
		if(fl_RegainWalkAnim[npc.index] < gameTime)
		{
			switch(i_GunMode[npc.index])
			{
				case 0:
				{
					if(npc.m_iChanged_WalkCycle != 2) 	
					{
						if(IsValidEntity(npc.m_iWearable1))
						{
							RemoveEntity(npc.m_iWearable1);
						}
						int iActivity = npc.LookupActivity("ACT_FT2_WALK");
						if(iActivity > 0) npc.StartActivity(iActivity);
						npc.m_iChanged_WalkCycle = 2;
						npc.m_bisWalking = true;
						npc.m_flSpeed = 300.0;
						if(npc.Anger)
							npc.m_flSpeed = 350.0;
						npc.StartPathing();
						f_NpcTurnPenalty[npc.index] = 1.0;
					}
				}
				case 1:
				{
					if(npc.m_iChanged_WalkCycle != 10) 	
					{
						int iActivity = npc.LookupActivity("ACT_FT_WALK");
						if(iActivity > 0) npc.StartActivity(iActivity);
						npc.m_iChanged_WalkCycle = 10;
						npc.m_bisWalking = true;
						npc.m_flSpeed = 50.0;
						if(npc.Anger)
							npc.m_flSpeed = 100.0;
						npc.StartPathing();
						f_NpcTurnPenalty[npc.index] = 1.0;
						if(IsValidEntity(npc.m_iWearable1))
						{
							RemoveEntity(npc.m_iWearable1);
						}
						npc.m_iWearable1 = npc.EquipItem("weapon_bone", "models/weapons/c_models/c_minigun/c_minigun.mdl");
						SetVariantString("1.0");
						AcceptEntityInput(npc.m_iWearable1, "SetModelScale");
					}					
				}
			}
			fl_RegainWalkAnim[npc.index] = 0.0;
		}
	}
	int client_victim = EntRefToEntIndex(i_GrabbedThis[npc.index]);
	if(IsValidEntity(client_victim))
	{
		if(npc.m_flNextRangedAttackHappening)
		{
			if(npc.m_flNextRangedAttackHappening < gameTime)
			{
				i_GrabbedThis[npc.index] = -1;
				AcceptEntityInput(client_victim, "ClearParent");
						
				float flPos[3]; // original
				float flAng[3]; // original
						
						
				npc.GetAttachment("RightHand", flPos, flAng);
				TeleportEntity(client_victim, flPos, NULL_VECTOR, {0.0,0.0,0.0});
						
				if(client_victim <= MaxClients)
				{
					SetEntityMoveType(client_victim, MOVETYPE_WALK); //can move XD
							
					TF2_AddCondition(client_victim, TFCond_LostFooting, 1.0);
					TF2_AddCondition(client_victim, TFCond_AirCurrent, 1.0);
							
					if(dieingstate[client_victim] == 0)
					{
						SetEntityCollisionGroup(client_victim, 5);
						b_ThisEntityIgnored[client_victim] = false;
					}
					Custom_Knockback(npc.index, client_victim, 3000.0, true, true);
				}
				else
				{
					b_NoGravity[npc.index] = true;
					b_CannotBeKnockedUp[npc.index] = true;
					npc.SetVelocity({0.0,0.0,0.0});
				}
				npc.m_flNextRangedAttackHappening = 0.0;	
				SDKHooks_TakeDamage(client_victim, npc.index, npc.index, 10000.0, DMG_CLUB, -1);
				i_TankAntiStuck[client_victim] = EntIndexToEntRef(npc.index);
				CreateTimer(0.1, CheckStuckNemesis, EntIndexToEntRef(client_victim), TIMER_FLAG_NO_MAPCHANGE);
				npc.PlayRangedSpecialSound();
			}
		}
	}
	else
	{
		if(npc.m_flNextRangedAttackHappening)
		{
			if(npc.m_flNextRangedAttackHappening - 5.75 < gameTime)
			{
				if(npc.m_iChanged_WalkCycle != 6 && npc.m_iChanged_WalkCycle != 5 && npc.m_iChanged_WalkCycle != 7) 
				{
					npc.m_iChanged_WalkCycle = 6;
					npc.m_bisWalking = false;
					npc.m_flSpeed = 600.0;
					if(npc.Anger)
							npc.m_flSpeed = 900.0;
					npc.StartPathing();
				}
				if(npc.flXenoInfectedSpecialHurtTime < gameTime && npc.m_flNextRangedAttackHappening - 1.5 > gameTime)
				{
					npc.flXenoInfectedSpecialHurtTime = gameTime + 0.4;
					npc.SetCycle(0.45);
				}
			}

			if(IsValidEnemy(npc.index, npc.m_iTarget))
			{
				float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
				float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
				if(flDistanceToTarget < Pow(NORMAL_ENEMY_MELEE_RANGE_FLOAT * 1.25, 2.0))
				{
					int Enemy_I_See;
						
					Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);

					//Target close enough to hit
					if(IsValidEntity(npc.m_iTarget) && IsValidEnemy(npc.index, Enemy_I_See))
					{
						int iActivity = npc.LookupActivity("ACT_FT2_GRABKILL");
						if(iActivity > 0) npc.StartActivity(iActivity);
						npc.m_iChanged_WalkCycle = 5;
						npc.m_bisWalking = false;
						npc.m_flSpeed = 0.0;
						PF_StopPathing(npc.index);
						npc.m_flDoingAnimation = gameTime + 5.0;
						npc.m_flNextRangedAttackHappening = gameTime + 3.1;
						fl_RegainWalkAnim[npc.index] = gameTime + 5.1;
						npc.PlayRangedSound();

						GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", f3_LastValidPosition[Enemy_I_See]);
						
						float flPos[3]; // original
						float flAng[3]; // original
					
						npc.GetAttachment("RightHand", flPos, flAng);
						
						TeleportEntity(Enemy_I_See, flPos, NULL_VECTOR, {0.0,0.0,0.0});
						
						CClotBody npcenemy = view_as<CClotBody>(Enemy_I_See);

						if(Enemy_I_See <= MaxClients)
						{
							SetEntityMoveType(Enemy_I_See, MOVETYPE_NONE); //Cant move XD
							SetEntityCollisionGroup(Enemy_I_See, 1);
							SetParent(npc.index, Enemy_I_See, "RightHand");
						}
						else
						{
							b_NoGravity[npc.index] = true;
							b_CannotBeKnockedUp[npc.index] = true;
							npcenemy.SetVelocity({0.0,0.0,0.0});
						}
						f_TankGrabbedStandStill[npcenemy.index] = GetGameTime() + 3.5;
						TeleportEntity(npcenemy.index, NULL_VECTOR, NULL_VECTOR, {0.0,0.0,0.0});
						i_GrabbedThis[npc.index] = EntIndexToEntRef(Enemy_I_See);
						b_DoNotUnStuck[Enemy_I_See] = true;
						f_NpcTurnPenalty[npc.index] = 1.0;
					}
				}
			}
			if(npc.m_iChanged_WalkCycle != 5) 
			{
				if(npc.m_flNextRangedAttackHappening - 0.6 < gameTime)
				{
					if(npc.m_iChanged_WalkCycle != 7) 
					{
						npc.m_iChanged_WalkCycle = 7;
						npc.m_bisWalking = false;
						npc.m_flSpeed = 0.0;
						PF_StopPathing(npc.index);
					}
				}
				if(npc.m_flNextRangedAttackHappening < gameTime)
				{
					if(npc.m_iChanged_WalkCycle != 2) 	
					{
						int iActivity = npc.LookupActivity("ACT_FT2_WALK");
						if(iActivity > 0) npc.StartActivity(iActivity);
						npc.m_iChanged_WalkCycle = 2;
						npc.m_bisWalking = true;
						npc.m_flSpeed = 300.0;
						if(npc.Anger)
							npc.m_flSpeed = 350.0;
						npc.StartPathing();
						f_NpcTurnPenalty[npc.index] = 1.0;
					}
					npc.m_flNextRangedAttackHappening = 0.0;			
				}	
			}
		}
	}

	if(npc.m_flAttackHappens)
	{
		if(f_NemesisHitBoxStart[npc.index] < gameTime && f_NemesisHitBoxEnd[npc.index] > gameTime)
		{
			Nemesis_AreaAttack(npc.index, 1500.0, {-40.0,-40.0,-40.0}, {40.0,40.0,40.0});
		}

		if(npc.m_flAttackHappens < gameTime)
		{
			if(npc.m_flDoingAnimation > gameTime)
			{
				if(IsValidEnemy(npc.index, npc.m_iTarget))
				{
					float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
					float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
					if(flDistanceToTarget < Pow(NORMAL_ENEMY_MELEE_RANGE_FLOAT * 2.0, 2.0))
					{

						if(npc.m_iChanged_WalkCycle != 3) 
						{
							//the enemy is still close, do another attack.
							float flPos[3]; // original
							float flAng[3]; // original
							npc.GetAttachment("RightHand", flPos, flAng);
							if(IsValidEntity(npc.m_iWearable5))
								RemoveEntity(npc.m_iWearable5);
						
							npc.m_iWearable5 = ParticleEffectAt(flPos, "spell_fireball_small_blue", 1.25);
							TeleportEntity(npc.m_iWearable5, flPos, flAng, NULL_VECTOR);
							SetParent(npc.index, npc.m_iWearable5, "RightHand");
							npc.m_flAttackHappens = gameTime + 2.0;
							npc.m_flDoingAnimation = gameTime + 2.0;
							f_NemesisHitBoxStart[npc.index] = gameTime + 0.65;
							f_NemesisHitBoxEnd[npc.index] = gameTime + 1.25;
							f_NemesisCauseInfectionBox[npc.index] = gameTime + 1.0;
							int iActivity = npc.LookupActivity("ACT_FT2_ATTACK_2");
							if(iActivity > 0) npc.StartActivity(iActivity);
							npc.m_iChanged_WalkCycle = 3;
							npc.m_bisWalking = false;
							npc.m_flSpeed = 50.0;
							if(npc.Anger)
								npc.m_flSpeed = 100.0;
							npc.StartPathing();
							f_NpcTurnPenalty[npc.index] = 0.25;
							npc.PlayMeleeSound();
						}
						else
						{
							npc.m_flAttackHappens = 0.0;
						}
					}
				}
			}
			else
			{
				if(npc.m_iChanged_WalkCycle != 2) 	
				{
					int iActivity = npc.LookupActivity("ACT_FT2_WALK");
					if(iActivity > 0) npc.StartActivity(iActivity);
					npc.m_iChanged_WalkCycle = 2;
					npc.m_bisWalking = true;
					npc.m_flSpeed = 300.0;
					if(npc.Anger)
							npc.m_flSpeed = 350.0;
					npc.StartPathing();
					f_NpcTurnPenalty[npc.index] = 1.0;
				}
				npc.m_flAttackHappens = 0.0;
			}
		}
	}
	if(IsValidEnemy(npc.index, npc.m_iTarget))
	{
		float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
		float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
		//Predict their pos.
		if(fl_OverrideWalkDest[npc.index] < gameTime)
		{
			if(flDistanceToTarget < npc.GetLeadRadius()) 
			{
				float vPredictedPos[3]; vPredictedPos = PredictSubjectPosition(npc, npc.m_iTarget);
				PF_SetGoalVector(npc.index, vPredictedPos);
			} 
			else 
			{
				PF_SetGoalEntity(npc.index, npc.m_iTarget);
			}	
		}


		int ActionToTake = -1;

		npc.m_flRangedArmor = 1.0;	//Due to his speed, ranged will deal less
		if(npc.m_flDoingAnimation > GetGameTime(npc.index)) //I am doing an animation or doing something else, default to doing nothing!
		{
			if(!npc.m_flNextRangedAttackHappening)
			{
				npc.m_flRangedArmor = 0.5;	//Due to his speed, ranged will deal less
			}
			ActionToTake = -1;
		}
		else if(i_GunMode[npc.index] == 0)
		{
			if(flDistanceToTarget < Pow(NORMAL_ENEMY_MELEE_RANGE_FLOAT * 1.50, 2.0) && npc.m_flNextMeleeAttack < GetGameTime(npc.index))
			{
				ActionToTake = 1;
			}
			else if(flDistanceToTarget > Pow(NORMAL_ENEMY_MELEE_RANGE_FLOAT * 1.50, 2.0) && npc.m_flNextRangedAttack < GetGameTime(npc.index))
			{
				ActionToTake = 2;
			}
		}
		else if(i_GunMode[npc.index] == 1)
		{
			if(npc.m_flJumpStartTime < GetGameTime(npc.index))
			{
				ActionToTake = 3;
			}			
		}

		/*
		TODO:
		If didnt attack for abit, sprints and grabs someone
		Can dodge projetiles and then equip rocket launcher to retaliate
		Same with minigun, its random what he chooses
		During any melee animation he does, he will ggain 50% ranged resistance
		Make him instantly crush any NPC enemy basically, mainly aoe attacks only
		all his attacks will be aoe and dodgeable easily

		Main threat is trying to do massive damage to him and taking him down before the timer runs out, being too greedy kill you, being too safe makes you lose with a timer.
		Most effective way is backstabbing during melee attacks.
		*/


		switch(ActionToTake)
		{
			case 1:
			{
				npc.m_flNextMeleeAttack = gameTime + 5.0;
				npc.m_flDoingAnimation = gameTime + 2.5;
				npc.m_flAttackHappens = gameTime + 1.25;
				float flPos[3]; // original
				float flAng[3]; // original
				npc.GetAttachment("RightHand", flPos, flAng);
				if(IsValidEntity(npc.m_iWearable5))
					RemoveEntity(npc.m_iWearable5);
		
				npc.m_iWearable5 = ParticleEffectAt(flPos, "spell_fireball_small_red", 1.0);
				TeleportEntity(npc.m_iWearable5, flPos, flAng, NULL_VECTOR);
				SetParent(npc.index, npc.m_iWearable5, "RightHand");
				f_NemesisHitBoxStart[npc.index] = gameTime + 0.45;
				f_NemesisHitBoxEnd[npc.index] = gameTime + 1.0;
				f_NemesisCauseInfectionBox[npc.index] = gameTime + 1.0;

				if(npc.m_iChanged_WalkCycle != 1) 
				{
					int iActivity = npc.LookupActivity("ACT_FT2_ATTACK_1");
					if(iActivity > 0) npc.StartActivity(iActivity);
					npc.m_iChanged_WalkCycle = 1;
					npc.m_bisWalking = false;
					npc.m_flSpeed = 50.0;
					if(npc.Anger)
							npc.m_flSpeed = 100.0;
					npc.StartPathing();
					f_NpcTurnPenalty[npc.index] = 0.25;
					npc.PlayMeleeSound();
				}
			}
			case 2:
			{
				npc.m_flNextRangedAttack = gameTime + 35.0;
				npc.m_flNextRangedAttackHappening = gameTime + 7.5;
				npc.flXenoInfectedSpecialHurtTime = gameTime + 1.25;
				npc.SetCycle(0.15);
				npc.m_flDoingAnimation = gameTime + 7.55;

				if(npc.m_iChanged_WalkCycle != 4) 
				{
					npc.PlayAngerSound();
					int iActivity = npc.LookupActivity("ACT_FT2_GRAB");
					if(iActivity > 0) npc.StartActivity(iActivity);
					npc.m_iChanged_WalkCycle = 4;
					npc.m_bisWalking = false;
					npc.m_flSpeed = 0.0;
					PF_StopPathing(npc.index);
					f_NpcTurnPenalty[npc.index] = 1.0;
				}
			}
			case 3:
			{
				npc.m_flJumpStartTime = gameTime + 0.1;
				npc.FaceTowards(vecTarget, 99999.9);

				vecTarget = PredictSubjectPositionForProjectiles(npc, npc.m_iTarget, 1300.0);
				float VecSave[3];
				VecSave = vecTarget;

				for(int repeat = 1; repeat <= 2; repeat++)
				{
					vecTarget = VecSave;
					//	if(flDistanceToTarget < 1000000.0)	// 1000 HU

					vecTarget[0] += GetRandomFloat(-50.0,50.0);
					vecTarget[1] += GetRandomFloat(-50.0,50.0);
					vecTarget[2] += GetRandomFloat(-50.0,50.0);

					i_GunAmmo[npc.index] -= 1;
						
					float damage = 105.0;

					if(npc.Anger)
					{
						damage = 150.0;
					}
					npc.FireRocket(vecTarget, damage, 1300.0, "models/weapons/w_bullet.mdl", 2.0,_, 45.0);	
				}
			}
		}
	}
	else
	{
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_iTarget = GetClosestTarget(npc.index);
	}
}

	
public Action RaidbossNemesis_ClotDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Valid attackers only.
	if(attacker < 1)
		return Plugin_Continue;
		
	RaidbossNemesis npc = view_as<RaidbossNemesis>(victim);
	
	if (npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}

	return Plugin_Changed;
}

public void RaidbossNemesis_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	RaidbossNemesis npc = view_as<RaidbossNemesis>(victim);
	if((GetEntProp(npc.index, Prop_Data, "m_iMaxHealth")/4) >= GetEntProp(npc.index, Prop_Data, "m_iHealth") && !npc.Anger) //npc.Anger after half hp/400 hp
	{
		if(IsValidEntity(npc.m_iWearable1))
		{
			RemoveEntity(npc.m_iWearable1);
		}
		i_GunMode[npc.index] = 1;
		i_GunAmmo[npc.index] = 500;
		f_NemesisSpecialDeathAnimation[npc.index] = GetGameTime(npc.index);
		npc.PlayBoomSound();
		npc.Anger = true; //	>:(

		int client = EntRefToEntIndex(i_GrabbedThis[npc.index]);
		if(IsValidEntity(client))
		{
			AcceptEntityInput(client, "ClearParent");
			b_NoGravity[npc.index] = true;
			b_CannotBeKnockedUp[npc.index] = true;
			npc.SetVelocity({0.0,0.0,0.0});
			if(IsValidClient(client))
			{
				SetEntityMoveType(client, MOVETYPE_WALK); //can move XD
				SetEntityCollisionGroup(client, 5);
			}
			
			float pos[3];
			float Angles[3];
			GetEntPropVector(npc.index, Prop_Data, "m_angRotation", Angles);

			GetEntPropVector(npc.index, Prop_Send, "m_vecOrigin", pos);
			TeleportEntity(client, pos, Angles, NULL_VECTOR);
		}	
	}
}

public void RaidbossNemesis_NPCDeath(int entity)
{
	RaidbossNemesis npc = view_as<RaidbossNemesis>(entity);
	if(!npc.m_bDissapearOnDeath)
	{
		npc.PlayDeathSound();
	}
	int client = EntRefToEntIndex(i_GrabbedThis[npc.index]);
	
	if(IsValidEntity(client))
	{
		AcceptEntityInput(client, "ClearParent");
		b_NoGravity[npc.index] = true;
		b_CannotBeKnockedUp[npc.index] = true;
		npc.SetVelocity({0.0,0.0,0.0});
		if(IsValidClient(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK); //can move XD
			SetEntityCollisionGroup(client, 5);
		}
		
		float pos[3];
		float Angles[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", Angles);

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(client, pos, Angles, NULL_VECTOR);
	}	
	int entity_death = CreateEntityByName("prop_dynamic_override");
	if(IsValidEntity(entity_death))
	{
		float pos[3];
		float Angles[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", Angles);
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(entity_death, pos, Angles, NULL_VECTOR);
		DispatchKeyValue(entity_death, "model", NEMESIS_MODEL);
		DispatchSpawn(entity_death);
		SetEntPropFloat(entity_death, Prop_Send, "m_flModelScale", 1.75); 
		SetEntityCollisionGroup(entity_death, 2);
		SetVariantString("ft2_death");
		AcceptEntityInput(entity_death, "SetAnimation");
		
		CreateTimer(15.0, Timer_RemoveEntity, EntIndexToEntRef(entity_death), TIMER_FLAG_NO_MAPCHANGE);

	}

	i_GrabbedThis[npc.index] = -1;
	SDKUnhook(npc.index, SDKHook_Think, RaidbossNemesis_ClotThink);
	SDKUnhook(npc.index, SDKHook_OnTakeDamage, RaidbossNemesis_ClotDamaged);
	
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	if(IsValidEntity(npc.m_iWearable2))
		RemoveEntity(npc.m_iWearable2);
	if(IsValidEntity(npc.m_iWearable3))
		RemoveEntity(npc.m_iWearable3);
	if(IsValidEntity(npc.m_iWearable4))
		RemoveEntity(npc.m_iWearable4);
	if(IsValidEntity(npc.m_iWearable5))
		RemoveEntity(npc.m_iWearable5);
	if(IsValidEntity(npc.m_iWearable6))
		RemoveEntity(npc.m_iWearable6);
	if(IsValidEntity(npc.m_iWearable7))
		RemoveEntity(npc.m_iWearable7);
		
//	AcceptEntityInput(npc.index, "KillHierarchy");
//	npc.Anger = false;
	Citizen_MiniBossDeath(entity);
}

void Nemesis_TryDodgeAttack(int entity)
{
	RaidbossNemesis npc = view_as<RaidbossNemesis>(entity);
	bool RocketInfrontOfMe = false;

	float flMyPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", flMyPos);
	static float hullcheckmaxs_Player[3];
	static float hullcheckmins_Player[3];
	flMyPos[2] += 18.0; //Step height.
	
	float ang[3];
	GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
	
	ang[0] = 0.0; //I dont want him to go up or down with his prediction.
	float vecForward_2[3];
			
	GetAngleVectors(ang, vecForward_2, NULL_VECTOR, NULL_VECTOR);
					
	float vecSwingStart_2[3]; vecSwingStart_2 = flMyPos;
				
	float ExtraDistance = 250.0;
	float vecSwingEnd_2[3];
	vecSwingEnd_2[0] = vecSwingStart_2[0] + vecForward_2[0] * ExtraDistance;
	vecSwingEnd_2[1] = vecSwingStart_2[1] + vecForward_2[1] * ExtraDistance;
	vecSwingEnd_2[2] = vecSwingStart_2[2] + vecForward_2[2] * ExtraDistance;

	if(b_IsGiant[entity])
	{
		hullcheckmaxs_Player = view_as<float>( { 30.0, 30.0, 80.0 } );
		hullcheckmins_Player = view_as<float>( { -30.0, -30.0, 0.0 } );	
	}
	else
	{
		hullcheckmaxs_Player = view_as<float>( { 24.0, 24.0, 42.0 } );
		hullcheckmins_Player = view_as<float>( { -24.0, -24.0, 0.0 } );		
	}

	Handle hTrace = TR_TraceHullFilterEx(vecSwingEnd_2, flMyPos, hullcheckmins_Player, hullcheckmaxs_Player, MASK_PLAYERSOLID, TraceRayHitProjectilesOnly, entity);
	int ref = TR_GetEntityIndex(hTrace);
	if(IsValidEntity(ref))
	{
		ref = EntRefToEntIndex(ref);
		RocketInfrontOfMe = true;
	}
	delete hTrace;

	if(RocketInfrontOfMe)
	{
		if(fl_StopDodgeCD[npc.index] < GetGameTime(npc.index))
		{
			if(npc.m_iChanged_WalkCycle != 8) 
			{
				int DodgeLeft;
				b_IgnoredByPlayerProjectiles[npc.index] = true;

				DodgeLeft = GetRandomInt(0,1);
				float PosToDodgeTo[3];

				if(DodgeLeft == 0)
				{
					int iActivity = npc.LookupActivity("ACT_DODGE_2");
					if(iActivity > 0) npc.StartActivity(iActivity);
					PosToDodgeTo = Nemesis_DodgeToDirection(npc, 200.0, -90.0);
				}
				else
				{
					int iActivity = npc.LookupActivity("ACT_DODGE_1");
					if(iActivity > 0) npc.StartActivity(iActivity);
					PosToDodgeTo = Nemesis_DodgeToDirection(npc, 200.0, 90.0);					
				}
				npc.m_iChanged_WalkCycle = 8;
				npc.m_bisWalking = false;
				npc.m_bAllowBackWalking = true;
				npc.m_flSpeed = 600.0;

				fl_OverrideWalkDest[npc.index] = GetGameTime(npc.index) + 1.5;
				if(IsValidEntity(npc.m_iTarget))
				{
					float vecTarget[3]; vecTarget = WorldSpaceCenter(ref);
					npc.FaceTowards(vecTarget);
				}
				PF_SetGoalVector(npc.index, PosToDodgeTo);
				npc.StartPathing();
				npc.m_flDoingAnimation = GetGameTime(npc.index) + 1.55;
				fl_StopDodge[npc.index] = GetGameTime(npc.index) + 0.5;
				fl_StopDodgeCD[npc.index] = GetGameTime(npc.index) + 50.0;
				fl_RegainWalkAnim[npc.index] = GetGameTime(npc.index) + 1.5;
				f_NpcTurnPenalty[npc.index] = 1.0;
			}
		}
	}
}

public bool TraceRayHitProjectilesOnly(int entity,int mask,any data)
{
	if(entity == 0)
	{
		return false;
	}
	if(b_Is_Player_Projectile[entity])
	{
		return true;
	}
	
	return false;
}


void Nemesis_AreaAttack(int entity, float damage, float m_vecMins_1[3], float m_vecMaxs_1[3])
{
	RaidbossNemesis npc = view_as<RaidbossNemesis>(entity);
	//focus a box around a certain part of the body, the arm for example.					
	float flPos[3]; // original
	float flAng[3]; // original
	npc.GetAttachment("RightHand", flPos, flAng);

	static float m_vecMaxs[3];
	static float m_vecMins[3];
	m_vecMaxs = m_vecMaxs_1;
	m_vecMins = m_vecMins_1;	

	for (int i = 1; i < MAXENTITIES; i++)
	{
		i_NemesisEntitiesHitAoeSwing[i] = -1;
	}
	Handle hTrace = TR_TraceHullFilterEx(flPos, flPos, m_vecMins, m_vecMaxs, MASK_SOLID, Nemeis_AoeAttack, entity);
	delete hTrace;

	for (int counter = 1; counter < MAXENTITIES; counter++)
	{
		if (i_NemesisEntitiesHitAoeSwing[counter] != -1)
		{
			if(IsValidEntity(i_NemesisEntitiesHitAoeSwing[counter]) && f_NemesisEnemyHitCooldown[i_NemesisEntitiesHitAoeSwing[counter]] < GetGameTime())
			{
				f_NemesisEnemyHitCooldown[i_NemesisEntitiesHitAoeSwing[counter]] = GetGameTime() + 0.15;
				SDKHooks_TakeDamage(i_NemesisEntitiesHitAoeSwing[counter], npc.index, npc.index, damage, DMG_CLUB, -1);
				npc.PlayMeleeHitSound();
			}
		}
		else
		{
			break;
		}
	}
	/*
	for(int client; client <= MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			static float m_vecMaxs_2[3];
			static float m_vecMins_2[3];
			static float f_pos[3];
			m_vecMaxs_2 = m_vecMaxs_1;
			m_vecMins_2 = m_vecMins_1;	
			f_pos = flPos;
			TE_DrawBox(client, f_pos, m_vecMins_2, m_vecMaxs_2, 0.1, view_as<int>({255, 0, 0, 255}));
		}
	}
	*/
}

static bool Nemeis_AoeAttack(int entity, int contentsMask, int filterentity)
{
	if(IsValidEnemy(filterentity,entity, true, true))
	{
		for(int i=1; i < (MAXENTITIES); i++)
		{
			if(i_NemesisEntitiesHitAoeSwing[i] == -1)
			{
				i_NemesisEntitiesHitAoeSwing[i] = entity;
				break;
			}
		}
	}
	return false;
}

public Action CheckStuckNemesis(Handle timer, any entid)
{
	int client = EntRefToEntIndex(entid);
	if(IsValidEntity(client))
	{
		b_DoNotUnStuck[client] = false;
		float flMyPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", flMyPos);
		static float hullcheckmaxs_Player[3];
		static float hullcheckmins_Player[3];

		if(IsValidClient(client)) //Player size
		{
			hullcheckmaxs_Player = view_as<float>( { 24.0, 24.0, 82.0 } );
			hullcheckmins_Player = view_as<float>( { -24.0, -24.0, 0.0 } );		
		}
		
		if(IsSpaceOccupiedIgnorePlayers(flMyPos, hullcheckmins_Player, hullcheckmaxs_Player, client))
		{
			if(IsValidClient(client)) //Player Unstuck, but give them a penalty for doing this in the first place.
			{
				int damage = SDKCall_GetMaxHealth(client) / 8;
				SDKHooks_TakeDamage(client, 0, 0, float(damage), DMG_GENERIC, -1, NULL_VECTOR);
			}
			TeleportEntity(client, f3_LastValidPosition[client], NULL_VECTOR, { 0.0, 0.0, 0.0 });
		}
		else
		{
			int tank = EntRefToEntIndex(i_TankAntiStuck[client]);
			if(IsValidEntity(tank))
			{
				bool Hit_something = Can_I_See_Enemy_Only(tank, client);
				//Target close enough to hit
				if(!Hit_something)
				{	
					if(IsValidClient(client)) //Player Unstuck, but give them a penalty for doing this in the first place.
					{
						int damage = SDKCall_GetMaxHealth(client) / 8;
						SDKHooks_TakeDamage(client, 0, 0, float(damage), DMG_GENERIC, -1, NULL_VECTOR);
					}
					TeleportEntity(client, f3_LastValidPosition[client], NULL_VECTOR, { 0.0, 0.0, 0.0 });
				}
			}
			else
			{
				//Just teleport back, dont fucking risk it.
				TeleportEntity(client, f3_LastValidPosition[client], NULL_VECTOR, { 0.0, 0.0, 0.0 });
			}
		}
	}
	return Plugin_Handled;
}



stock float[] Nemesis_DodgeToDirection(CClotBody npc, float extra_backoff = 64.0, float Angle = -90.0)
{
	float botPos[3];
	botPos = WorldSpaceCenter(npc.index);
	
	// compute our desired destination
	float pathTarget[3];
	
		
	//https://forums.alliedmods.net/showthread.php?t=278691 im too stupid for vectors.
	float ang[3];
	GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
	
	ang[0] = 0.0; //I dont want him to go up or down with his prediction.
	ang[1] += Angle; //try to the left/right.
	float vecForward_2[3];
			
	GetAngleVectors(ang, vecForward_2, NULL_VECTOR, NULL_VECTOR);
					
	float vecSwingStart_2[3]; vecSwingStart_2 = botPos;
				
	float vecSwingEnd_2[3];
	vecSwingEnd_2[0] = vecSwingStart_2[0] + vecForward_2[0] * extra_backoff;
	vecSwingEnd_2[1] = vecSwingStart_2[1] + vecForward_2[1] * extra_backoff;
	vecSwingEnd_2[2] = vecSwingStart_2[2] + vecForward_2[2] * extra_backoff;
			
	Handle trace_2; 
			
	trace_2 = TR_TraceRayFilterEx(botPos, vecSwingEnd_2, MASK_SOLID, RayType_EndPoint, HitOnlyTargetOrWorld, 0); //If i hit a wall, i stop retreatring and accept death, for now!
	TR_GetEndPosition(pathTarget, trace_2);

	delete trace_2;

	Handle trace_3; //2nd one, make sure to actually hit the ground!
	
	trace_3 = TR_TraceRayFilterEx(pathTarget, {89.0, 1.0, 0.0}, MASK_SOLID, RayType_Infinite, HitOnlyTargetOrWorld, 0); //If i hit a wall, i stop retreatring and accept death, for now!
	
	TR_GetEndPosition(pathTarget, trace_3);
	
	delete trace_3;
	
	/*
	int g_iPathLaserModelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
	TE_SetupBeamPoints(botPos, pathTarget, g_iPathLaserModelIndex, g_iPathLaserModelIndex, 0, 30, 5.0, 1.0, 0.1, 5, 0.0, view_as<int>({255, 0, 255, 255}), 30);
	TE_SendToAll();
	*/
	
	pathTarget[2] += 20.0; //Clip them up, minimum crouch level preferred, or else the bots get really confused and sometimees go otther ways if the player goes up or down somewhere, very thin stairs break these bots.
	
	return pathTarget;
}

#define MAX_TARGETS_HIT_NEMESIS 64

void Nemesis_DoInfectionThrow(int entity, int MaxThrowCount, float StartVec[3])
{
	int count;
	int targets[MAX_TARGETS_HIT_NEMESIS];

	for(int client; client<=MaxClients; client++)
	{
		if(IsValidEntity(client) && IsValidEnemy(entity, client, false, false))
		{
			bool Hit_something = Can_I_See_Enemy_Only(entity, client);
			//Target close enough to hit
			if(Hit_something)
			{	
				if(count < MAX_TARGETS_HIT_NEMESIS)
				{
					targets[count++] = client;
				}
				else
				{
					break;
				}
			}
		}
	}
	for(int entitycount; entitycount<i_MaxcountNpc_Allied; entitycount++)
	{
		int enemy = EntRefToEntIndex(i_ObjectsNpcs_Allied[entitycount]);
		if(IsValidEntity(enemy) && IsValidEnemy(entity, enemy, false, false))
		{
			bool Hit_something = Can_I_See_Enemy_Only(entity, enemy);
			//Target close enough to hit
			if(Hit_something)
			{	
				if(count < MAX_TARGETS_HIT_NEMESIS)
				{
					targets[count++] = enemy;
				}
				else
				{
					break;
				}
			}
		}
	}

	SortIntegers(targets, count, Sort_Random);

	for(int Repeat; Repeat<MaxThrowCount; Repeat++)
	{
		if(count)
		{
			// Choosen a random one in our list
			count--;	// This decreases the max entries
			int target = targets[count];	// This grabs the entry at the very end
			
			float vecJumpVel[3];
			float VicLoc[3];

			//poisition of the enemy we random decide to shoot.
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", VicLoc);

			float gravity = GetEntPropFloat(entity, Prop_Data, "m_flGravity");
				
			if(gravity <= 0.0)
				gravity = FindConVar("sv_gravity").FloatValue;
			
			// How fast does the headcrab need to travel to reach the position given gravity?
			float flActualHeight = VicLoc[2] - StartVec[2];
			float height = flActualHeight;
			if ( height < 72 )
			{
				height = 72.0;
			}
			float additionalHeight = 0.0;
			
			if ( height < 35 )
			{
				additionalHeight = 50.0;
			}
			
			height += additionalHeight;
			
			float speed = SquareRoot( 2 * gravity * height );
			float time = speed / gravity;
		
			time += SquareRoot( (2 * additionalHeight) / gravity );
			
			// Scale the sideways velocity to get there at the right time
			SubtractVectors( VicLoc, StartVec, vecJumpVel );
			vecJumpVel[0] /= time;
			vecJumpVel[1] /= time;
			vecJumpVel[2] /= time;
		
			// Speed to offset gravity at the desired height.
			vecJumpVel[2] = speed;
			
			// Don't jump too far/fast.
			float flJumpSpeed = GetVectorLength(vecJumpVel);
			float flMaxSpeed = 1250.0;
			if ( flJumpSpeed > flMaxSpeed )
			{
				vecJumpVel[0] *= flMaxSpeed / flJumpSpeed;
				vecJumpVel[1] *= flMaxSpeed / flJumpSpeed;
				vecJumpVel[2] *= flMaxSpeed / flJumpSpeed;
			}

			float direction[3];
			int prop = CreateEntityByName("prop_physics_multiplayer");
			if(IsValidEntity(prop))
			{
				DispatchKeyValue(prop, "model", INFECTION_MODEL);
				DispatchKeyValue(prop, "physicsmode", "2");
				DispatchKeyValue(prop, "solid", "0");
				DispatchKeyValue(prop, "massScale", "1.0");
				DispatchKeyValue(prop, "spawnflags", "6");

				DispatchKeyValue(prop, "modelscale", "1.0");
				DispatchKeyValueVector(prop, "origin",	 StartVec);
				direction[2] -= 180.0;
				direction[1] = GetRandomFloat(-180.0, 180.0);
				DispatchKeyValueVector(prop, "angles",	 direction);
				DispatchSpawn(prop);
				TeleportEntity(prop, NULL_VECTOR, NULL_VECTOR, vecJumpVel);
				SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
				SetEntityRenderColor(prop, 0, 200, 0, 255);
				SetEntityCollisionGroup(prop, 1); //COLLISION_GROUP_DEBRIS_TRIGGER
				SetEntProp(prop, Prop_Send, "m_usSolidFlags", 12); 
				SetEntProp(prop, Prop_Data, "m_nSolidType", 6); 
				CreateTimer(1.0, Timer_RemoveEntity, EntIndexToEntRef(prop), TIMER_FLAG_NO_MAPCHANGE);
				
			//	int particle = ParticleEffectAt(StartVec, "spellbook_minor_fire", 1.0);
			//	SetParent(prop, particle, "");

				spawnRing_Vectors(VicLoc, INFECTION_RANGE * 2.0, 0.0, 0.0, 5.0, "materials/sprites/laserbeam.vmt", 0, 255, 0, 200, 1, INFECTION_DELAY, 5.0, 0.0, 1);	
				VicLoc[2] -= 5.0;
				spawnRing_Vectors(VicLoc, 0.0, 0.0, 0.0, 5.0, "materials/sprites/laserbeam.vmt", 0, 255, 0, 200, 1, INFECTION_DELAY, 5.0, 0.0, 1,INFECTION_RANGE * 2.0);	
			}
			float damage = 500.0;

			DataPack pack;
			CreateDataTimer(INFECTION_DELAY, Nemesis_Infection_Throw, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(EntIndexToEntRef(entity)); 	//who this attack belongs to
			pack.WriteCell(damage);
			pack.WriteCell(VicLoc[0]);
			pack.WriteCell(VicLoc[1]);
			pack.WriteCell(VicLoc[2]);
		}
	}
}

public Action Nemesis_Infection_Throw(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	float damage = pack.ReadCell();
	float origin[3];
	origin[0] = pack.ReadCell();
	origin[1] = pack.ReadCell();
	origin[2] = pack.ReadCell();
	if(IsValidEntity(entity))
	{
		Explode_Logic_Custom(damage, entity, entity, -1, origin, INFECTION_RANGE, _, _, true, _, _, 1.0, NemesisHitInfection);
		int particle = ParticleEffectAt(origin, "green_wof_sparks", 1.0);
		float Ang[3];
		Ang[0] = -90.0;
		TeleportEntity(particle, NULL_VECTOR, Ang, NULL_VECTOR);
		EmitSoundToAll("weapons/cow_mangler_explode.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, origin);
	}
	return Plugin_Handled;
}


void NemesisHitInfection(int entity, int victim)
{
	if(f_NemesisImmuneToInfection[victim] < GetGameTime())
	{
		//this wont work on npcs, too unfair.
		if(IsValidClient(victim))
		{
			f_NemesisImmuneToInfection[victim] = GetGameTime() + 15.0;
			float HudY = -1.0;
			float HudX = -1.0;
			SetHudTextParams(HudX, HudY, 3.0, 50, 255, 50, 255);
			SetGlobalTransTarget(victim);
			ShowHudText(victim,  -1, "%t", "You have been Infected by Nemesis");
			ClientCommand(victim, "playgamesound items/powerup_pickup_plague_infected.wav");		
			float flPos[3];
			GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", flPos);
			flPos[2] += 100.0;
			int particle = ParticleEffectAt_Building_Custom(flPos, "powerup_icon_plague", victim);
			flPos[2] -= 100.0;
			int particle2 = ParticleEffectAt_Building_Custom(flPos, "powerup_plague_carrier", victim);
			CreateTimer(10.0, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(10.0, Timer_RemoveEntity, EntIndexToEntRef(particle2), TIMER_FLAG_NO_MAPCHANGE);
			int InfectionCount = 20;
			StartBleedingTimer_Against_Client(victim, entity, 25.0, InfectionCount);
			DataPack pack;
			CreateDataTimer(0.5, Timer_Nemesis_Infect_Allies, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(EntIndexToEntRef(victim));
			pack.WriteCell(EntIndexToEntRef(entity));
			pack.WriteCell(EntIndexToEntRef(particle));
			pack.WriteCell(EntIndexToEntRef(particle2));
			pack.WriteCell(InfectionCount);
		}
	}
}
public Action Timer_Nemesis_Infect_Allies(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = EntRefToEntIndex(pack.ReadCell());
	int entity = EntRefToEntIndex(pack.ReadCell());
	int Particle_entity = EntRefToEntIndex(pack.ReadCell());
	int Particle_entity_2 = EntRefToEntIndex(pack.ReadCell());
	if(!IsValidEntity(entity))
	{
		if(IsValidEntity(Particle_entity))
		{
			RemoveEntity(Particle_entity);
		}
		if(IsValidEntity(Particle_entity_2))
		{
			RemoveEntity(Particle_entity_2);
		}
		return Plugin_Stop;
	}
	if(!IsValidEnemy(entity, client))
	{
		if(IsValidEntity(Particle_entity))
		{
			RemoveEntity(Particle_entity);
		}
		if(IsValidEntity(Particle_entity_2))
		{
			RemoveEntity(Particle_entity_2);
		}
		return Plugin_Stop;
	}


	//everything is valid, infect nearby allies.
	//dont make it work on npcs, would be unfair.
	for(int AllyClient = 1; AllyClient <= MaxClients; AllyClient++)
	{
		if(IsValidEnemy(entity, AllyClient) && AllyClient != client)
		{
			float vAngles[3];				
			float entity_angles[3];						
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vAngles); 
			GetEntPropVector(AllyClient, Prop_Data, "m_vecAbsOrigin", entity_angles); 				
			float Distance = GetVectorDistance(vAngles, entity_angles);
			if(Distance < 65.0)
			{		
				NemesisHitInfection(entity, AllyClient);
			}
		}
	}
	int bleed_count = pack.ReadCell();
	if(bleed_count < 1)
	{
		if(IsValidEntity(Particle_entity))
		{
			RemoveEntity(Particle_entity);
		}
		if(IsValidEntity(Particle_entity_2))
		{
			RemoveEntity(Particle_entity_2);
		}
		return Plugin_Stop;
	}

	pack.Position--;
	pack.WriteCell(bleed_count-1, false);
	return Plugin_Continue;
}