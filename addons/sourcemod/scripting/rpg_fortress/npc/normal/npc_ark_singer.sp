#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] = {
	"npc/combine_soldier/die1.wav",
	"npc/combine_soldier/die2.wav",
	"npc/combine_soldier/die3.wav"
};

static const char g_HurtSound[][] = {
	"npc/combine_soldier/pain1.wav",
	"npc/combine_soldier/pain2.wav",
	"npc/combine_soldier/pain3.wav"
};

static const char g_IdleSound[][] = {
	"npc/combine_soldier/vo/prison_soldier_bunker1.wav",
	"npc/combine_soldier/vo/prison_soldier_bunker2.wav",
	"npc/combine_soldier/vo/prison_soldier_bunker3.wav"
};

static const char g_IdleAlertedSounds[][] = {
	"npc/combine_soldier/vo/prison_soldier_leader9dead.wav"
};

static const char g_RangedAttackSounds[][] = {
	"weapons/irifle/irifle_fire2.wav"
};

static const char g_RangedSpecialAttackSoundsSecondary[][] = {
	"npc/combine_soldier/vo/prison_soldier_fallback_b4.wav"
};

void ArkSinger_OnMapStart_NPC()
{
	PrecacheModel("models/effects/combineball.mdl");
	for (int i = 0; i < (sizeof(g_DeathSounds));	   i++) { PrecacheSound(g_DeathSounds[i]);	   }
	for (int i = 0; i < (sizeof(g_IdleSound));	i++) { PrecacheSound(g_IdleSound[i]);	}
	for (int i = 0; i < (sizeof(g_HurtSound));	i++) { PrecacheSound(g_HurtSound[i]);	}
	for (int i = 0; i < (sizeof(g_IdleAlertedSounds));	i++) { PrecacheSound(g_IdleAlertedSounds[i]);	}
	for (int i = 0; i < (sizeof(g_RangedAttackSounds));	i++) { PrecacheSound(g_RangedAttackSounds[i]);	}
	for (int i = 0; i < (sizeof(g_RangedSpecialAttackSoundsSecondary));	i++) { PrecacheSound(g_RangedSpecialAttackSoundsSecondary[i]);	}
}

methodmap ArkSinger < CClotBody
{
	public void PlayIdleSound()
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;

		EmitSoundToAll(g_IdleSound[GetRandomInt(0, sizeof(g_IdleSound) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);

		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(24.0, 48.0);
	}
	public void PlayHurtSound()
	{
		EmitSoundToAll(g_HurtSound[GetRandomInt(0, sizeof(g_HurtSound) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayRangedSound()
	{
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayDeathSound() 
	{
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayKilledEnemySound() 
	{
		EmitSoundToAll(g_IdleAlertedSounds[GetRandomInt(0, sizeof(g_IdleAlertedSounds) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(5.0, 10.0);
	}
	public void PlayRangedSpecialAttackSecondarySound()
	{
		EmitSoundToAll(g_RangedSpecialAttackSoundsSecondary[GetRandomInt(0, sizeof(g_RangedSpecialAttackSoundsSecondary) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}

	public ArkSinger(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		ArkSinger npc = view_as<ArkSinger>(CClotBody(vecPos, vecAng, COMBINE_CUSTOM_MODEL, "1.15", "12000", ally, false,_,_,_,_));
		
		i_NpcInternalId[npc.index] = ARK_SINGER;
		
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");
		
		npc.SetActivity("ACT_IDLE_PISTOL");

		npc.m_bisWalking = false;

		npc.m_bDissapearOnDeath = false;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;	
		npc.m_iNpcStepVariation = STEPTYPE_COMBINE;

		f3_SpawnPosition[npc.index][0] = vecPos[0];
		f3_SpawnPosition[npc.index][1] = vecPos[1];
		f3_SpawnPosition[npc.index][2] = vecPos[2];
		
		SDKHook(npc.index, SDKHook_OnTakeDamage, ArkSinger_OnTakeDamage);
		SDKHook(npc.index, SDKHook_Think, ArkSinger_ClotThink);

		npc.Anger = false;
		npc.m_iAttacksTillReload = 4;
		npc.m_iOverlordComboAttack = 20;

		SetEntityRenderMode(npc.index, RENDER_TRANSCOLOR);
		SetEntityRenderColor(npc.index, 255, 200, 200, 255);
		
		npc.m_iWearable1 = npc.EquipItem("partyhat", "models/player/items/spy/spy_party_phantom.mdl");
		SetVariantString("2.0");
		AcceptEntityInput(npc.m_iWearable2, "SetModelScale");
		
		npc.m_iWearable2 = npc.EquipItem("partyhat", "models/player/items/spy/spy_card_hat.mdl");
		SetVariantString("1.25");
		AcceptEntityInput(npc.m_iWearable2, "SetModelScale");

		SetEntityRenderMode(npc.m_iWearable1, RENDER_TRANSCOLOR);
		SetEntityRenderColor(npc.m_iWearable1, 255, 200, 200, 255);

		SetEntityRenderMode(npc.m_iWearable2, RENDER_TRANSCOLOR);
		SetEntityRenderColor(npc.m_iWearable2, 255, 200, 200, 255);

		PF_StopPathing(npc.index);
		npc.m_bPathing = false;
		return npc;
	}
	
}

//TODO 
//Rewrite
public void ArkSinger_ClotThink(int iNPC)
{
	ArkSinger npc = view_as<ArkSinger>(iNPC);

	SetVariantInt(1);
	AcceptEntityInput(iNPC, "SetBodyGroup");

	float gameTime = GetGameTime(npc.index);

	//some npcs deservere full update time!
	if(npc.m_flNextDelayTime > gameTime)
	{
		return;
	}

	npc.m_flNextDelayTime = gameTime;// + DEFAULT_UPDATE_DELAY_FLOAT;
	
	npc.Update();	

	if(npc.m_blPlayHurtAnimation && npc.m_flDoingAnimation < gameTime) //Dont play dodge anim if we are in an animation.
	{
		npc.AddGesture("ACT_GESTURE_FLINCH_HEAD", false);
		npc.PlayHurtSound();
		npc.m_blPlayHurtAnimation = false;
	}

	if(npc.m_flNextThinkTime > gameTime)
	{
		return;
	}
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	// npc.m_iTarget comes from here.
	Npc_Base_Thinking(iNPC, 500.0, "ACT_CUSTOM_WALK_BOW", "ACT_IDLE_PISTOL", 170.0, gameTime);

	if(npc.Anger)
	{
		if(--npc.m_iOverlordComboAttack < 1)
			npc.Anger = false;
	}
	else if(npc.m_iOverlordComboAttack > 19)
	{
		if(IsValidEnemy(npc.index, npc.m_iTarget))
		{
			npc.Anger = true;
			
			float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
			npc.FaceTowards(vecTarget, 30000.0);
			
			npc.PlayRangedSpecialAttackSecondarySound();
			npc.AddGesture("ACT_METROPOLICE_POINT");
			
			npc.m_flDoingAnimation = gameTime + 0.9;
			npc.m_flNextRangedAttackHappening = 0.0;
			npc.m_bisWalking = false;
			PF_StopPathing(npc.index);
			npc.m_bPathing = false;

			f_SingerBuffedFor[npc.index] = gameTime + (npc.m_iOverlordComboAttack * 0.25);

			float pos[3];
			int team = GetEntProp(npc.index, Prop_Send, "m_iTeamNum");
			int entity = -1;
			while((entity = FindEntityByClassname(entity, "base_boss")) != -1)
			{
				if(entity != npc.index && !b_NpcHasDied[entity] && GetEntProp(entity, Prop_Send, "m_iTeamNum") != team)
				{
					GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
					if(GetVectorDistance(pos, vecTarget, true) < 600000.0)	// 775 HU
					{
						f_SingerBuffedFor[entity] = f_SingerBuffedFor[npc.index];
					}
				}
			}
			
			return;
		}
	}

	if(npc.m_flNextRangedAttackHappening)
	{
		if(IsValidEnemy(npc.index, npc.m_iTarget))
		{
			float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
			npc.FaceTowards(vecTarget, 30000.0);
			if(npc.m_flNextRangedAttackHappening < gameTime)
			{
				npc.m_flNextRangedAttackHappening = 0.0;
				
				float vPredictedPos[3]; vPredictedPos = PredictSubjectPositionForProjectiles(npc, npc.m_iTarget, 800.0);
				npc.FireRocket(vPredictedPos, 250.0, 800.0, "models/effects/combineball.mdl");
				npc.PlayRangedAttackSecondarySound();
				// Scarlet Singer (50% dmg)

				if(npc.m_iTarget <= MaxClients)
					Stats_AddNeuralDamage(npc.m_iTarget, 80.0);
			}
		}
	}
	
	if(IsValidEnemy(npc.index, npc.m_iTarget))
	{
		float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
		float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
			
		//Predict their pos.
		if(flDistanceToTarget < npc.GetLeadRadius()) 
		{
			float vPredictedPos[3]; vPredictedPos = PredictSubjectPosition(npc, npc.m_iTarget);
			
			PF_SetGoalVector(npc.index, vPredictedPos);
		}
		else
		{
			PF_SetGoalEntity(npc.index, npc.m_iTarget);
		}
		//Get position for just travel here.

		if(npc.m_flDoingAnimation > gameTime) //I am doing an animation or doing something else, default to doing nothing!
		{
			npc.m_iState = -1;
		}
		else if(flDistanceToTarget < 160000 && npc.m_flNextRangedAttack < gameTime)
		{
			npc.m_iState = 1;
		}
		else 
		{
			npc.m_iState = 0; //stand and look if close enough.
		}
		
		switch(npc.m_iState)
		{
			case -1:
			{
				return; //Do nothing.
			}
			case 0:
			{
				//Walk to target
				if(!npc.m_bPathing)
					npc.StartPathing();
					
				npc.m_bisWalking = true;
				if(npc.m_iChanged_WalkCycle != 4) 	
				{
					npc.m_iChanged_WalkCycle = 4;
					npc.SetActivity("ACT_CUSTOM_WALK_BOW");
				}
			}
			case 1:
			{			
				int Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);
				if(IsValidEntity(Enemy_I_See) && IsValidEnemy(npc.index, Enemy_I_See))
				{
					npc.m_iTarget = Enemy_I_See;

					npc.AddGesture("ACT_MELEE_ATTACK_SWING_GESTURE");

					npc.m_flNextRangedAttackHappening = gameTime + 0.4;

					npc.m_flDoingAnimation = gameTime + 0.7;
					npc.m_flNextRangedAttack = gameTime + (f_SingerBuffedFor[npc.index] > gameTime ? 1.5 : 2.0);

					npc.m_bisWalking = false;
					PF_StopPathing(npc.index);
					npc.m_bPathing = false;
				}
			}
		}
	}

	npc.PlayIdleSound();
}

public Action ArkSinger_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker < 1)
		return Plugin_Continue;

	ArkSinger npc = view_as<ArkSinger>(victim);

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flHeadshotCooldown < gameTime)
	{
		npc.m_flHeadshotCooldown = gameTime + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
		if(!npc.Anger)
			npc.m_iOverlordComboAttack++;
	}

	return Plugin_Changed;
}

void ArkSinger_NPCDeath(int entity)
{
	ArkSinger npc = view_as<ArkSinger>(entity);
	if(!npc.m_bGib)
		npc.PlayDeathSound();
	
	SDKUnhook(entity, SDKHook_OnTakeDamage, ArkSinger_OnTakeDamage);
	SDKUnhook(entity, SDKHook_Think, ArkSinger_ClotThink);

	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	
	if(IsValidEntity(npc.m_iWearable2))
		RemoveEntity(npc.m_iWearable2);
	
	if(IsValidEntity(npc.m_iWearable3))
		RemoveEntity(npc.m_iWearable3);
}


