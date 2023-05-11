#pragma semicolon 1
#pragma newdecls required
 
static const char g_DeathSounds[][] =
{
	"npc/zombine/zombine_die1.wav"
};

static const char g_HurtSounds[][] =
{
	"npc/zombine/zombine_pain1.wav",
	"npc/zombine/zombine_pain2.wav",
	"npc/zombine/zombine_pain3.wav",
	"npc/zombine/zombine_pain4.wav"
};

static const char g_IdleAlertedSounds[][] =
{
	"npc/zombine/zombine_alert1.wav",
	"npc/zombine/zombine_alert2.wav",
	"npc/zombine/zombine_alert3.wav",
	"npc/zombine/zombine_alert4.wav",
	"npc/zombine/zombine_alert5.wav",
	"npc/zombine/zombine_alert6.wav",
	"npc/zombine/zombine_alert7.wav"
};

static const char g_AngerSounds[][] =
{
	"npc/zombine/zombine_charge1.wav",
	"npc/zombine/zombine_charge2.wav"
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/bow_shoot.wav",
};

methodmap FirstToTalk < CClotBody
{
	public void PlayIdleSound()
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		
		EmitCustomToAll(g_IdleAlertedSounds[GetRandomInt(0, sizeof(g_IdleAlertedSounds) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME,_);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(12.0, 24.0);
	}
	public void PlayHurtSound()
	{
		EmitCustomToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME,_);
	}
	public void PlayDeathSound() 
	{
		EmitCustomToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME,_);
	}
	public void PlayAngerSound()
 	{
		EmitCustomToAll(g_AngerSounds[GetRandomInt(0, sizeof(g_AngerSounds) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME,_);
	}
	public void PlayMeleeSound()
 	{
		EmitCustomToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME,_);
	}
	
	public FirstToTalk(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		FirstToTalk npc = view_as<FirstToTalk>(CClotBody(vecPos, vecAng, COMBINE_CUSTOM_MODEL, "1.15", "3150", ally, false));
		// 21000 x 0.15

		i_NpcInternalId[npc.index] = FIRSTTOTALK;
		npc.SetActivity("ACT_CUSTOM_WALK_SPEAR");
		
		npc.m_iBleedType = BLEEDTYPE_SEABORN;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_SEABORN;
		
		SDKHook(npc.index, SDKHook_OnTakeDamage, FirstToTalk_TakeDamage);
		SDKHook(npc.index, SDKHook_Think, FirstToTalk_ClotThink);
		
		npc.m_flSpeed = 200.0;	// 0.8 x 250
		npc.m_flGetClosestTargetTime = 0.0;

		npc.m_flNextMeleeAttack = 0.0;
		npc.m_flNextRangedAttack = GetGameTime(npc.index) + 30.0;
		
		SetEntityRenderMode(npc.index, RENDER_TRANSCOLOR);
		SetEntityRenderColor(npc.index, 50, 50, 255, 255);
		
		npc.m_iWearable1 = npc.EquipItem("weapon_bone", "models/workshop/weapons/c_models/c_xms_cold_shoulder/c_xms_cold_shoulder.mdl");
		SetVariantString("3.0");
		AcceptEntityInput(npc.m_iWearable1, "SetModelScale");
		
		npc.StartPathing();
		return npc;
	}
}

public void FirstToTalk_ClotThink(int iNPC)
{
	FirstToTalk npc = view_as<FirstToTalk>(iNPC);

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
		return;
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(npc.m_blPlayHurtAnimation)
	{
		//npc.AddGesture("ACT_GESTURE_FLINCH_HEAD", false);
		npc.PlayHurtSound();
		npc.m_blPlayHurtAnimation = false;
	}
	
	if(npc.m_flNextThinkTime > gameTime)
		return;
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	if(npc.m_iTarget && !IsValidEnemy(npc.index, npc.m_iTarget))
		npc.m_iTarget = 0;
	
	if(!npc.m_iTarget || npc.m_flGetClosestTargetTime < gameTime)
	{
		npc.m_iTarget = GetClosestTarget(npc.index);
		npc.m_flGetClosestTargetTime = gameTime + 1.0;
	}
	
	if(npc.m_iTarget > 0)
	{
		float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
		float distance = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);		
		
		if(npc.m_flDoingAnimation > gameTime)
		{
			npc.StopPathing();
		}
		else
		{
			if(distance < npc.GetLeadRadius())
			{
				float vPredictedPos[3]; vPredictedPos = PredictSubjectPosition(npc, npc.m_iTarget);
				PF_SetGoalVector(npc.index, vPredictedPos);
			}
			else 
			{
				PF_SetGoalEntity(npc.index, npc.m_iTarget);
			}

			npc.StartPathing();

			if(b_NpcIsInvulnerable[npc.index])
			{
				b_NpcIsInvulnerable[npc.index] = false;
				npc.SetActivity("ACT_CUSTOM_WALK_SPEAR");
			}
		}
		
		if(npc.m_flAttackHappens)
		{
			if(npc.m_flAttackHappens < gameTime)
			{
				npc.m_flAttackHappens = 0.0;
				
				npc.FaceTowards(vecTarget, 15000.0);

				npc.PlayMeleeSound();
				npc.FireArrow(vecTarget, 90.0, 1200.0);
				// 600 x 0.15

				SeaSlider_AddNeuralDamage(npc.m_iTarget, npc.index, 36);
				// 600 x 0.4 x 0.15
			}
		}

		if(distance < 250000.0 && npc.m_flNextMeleeAttack < gameTime)	// 2.5 * 200
		{
			int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
			if(IsValidEnemy(npc.index, target))
			{
				npc.m_iTarget = target;

				if(npc.m_flNextRangedAttack < gameTime)
				{
					npc.PlayAngerSound();
					npc.SetActivity("ACT_MUDROCK_RAGE");

					vecTarget[2] += 10.0;

					DataPack pack = new DataPack();
					pack.WriteCell(EntIndexToEntRef(npc.index));
					pack.WriteFloat(vecTarget[0]);
					pack.WriteFloat(vecTarget[1]);
					pack.WriteFloat(vecTarget[2]);

					CreateTimer(5.0, FirstToTalk_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(5.75, FirstToTalk_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(6.5, FirstToTalk_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(7.25, FirstToTalk_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(8.0, FirstToTalk_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(8.75, FirstToTalk_Timer, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);

					spawnRing_Vectors(vecTarget, 650.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 255, 50, 50, 200, 1, 9.0, 6.0, 0.1, 1);

					npc.m_flDoingAnimation = gameTime + 10.0;
					npc.m_flNextMeleeAttack = gameTime + 12.0;
					npc.m_flNextRangedAttack = gameTime + 40.0;
				}
				else
				{
					npc.AddGesture("ACT_CUSTOM_ATTACK_SPEAR");
					
					npc.m_flAttackHappens = gameTime + 0.35;

					npc.m_flDoingAnimation = gameTime + 1.0;
					npc.m_flNextMeleeAttack = gameTime + 3.0;
				}
			}
		}
	}
	else
	{
		npc.StopPathing();
	}

	npc.PlayIdleSound();
}

public Action FirstToTalk_Timer(Handle timer, DataPack pack)
{
	pack.Reset();
	FirstToTalk npc = view_as<FirstToTalk>(EntRefToEntIndex(pack.ReadCell()));
	if(npc.index != INVALID_ENT_REFERENCE)
	{
		float vecPos[3];
		vecPos[0] = pack.ReadFloat();
		vecPos[1] = pack.ReadFloat();
		vecPos[2] = pack.ReadFloat();

		spawnRing_Vectors(vecPos, 10.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 255, 50, 50, 200, 1, 0.4, 6.0, 0.1, 1, 650.0);

		DoExlosionTraceCheck(vecPos, 325.0, npc.index);
		// 600 x 0.15

		int victim;
		int armor = -9999999;
		for(int i; i < sizeof(HitEntitiesSphereExplosionTrace); i++)
		{
			if(!HitEntitiesSphereExplosionTrace[i][npc.index])
				break;
			
			int myArmor = 1;
			if(HitEntitiesSphereExplosionTrace[i][npc.index] <= MaxClients)
				myArmor = Armor_Charge[HitEntitiesSphereExplosionTrace[i][npc.index]];
			
			if(myArmor > armor)
			{
				
			}
		}
	}
	return Plugin_Stop;
}

public Action FirstToTalk_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker < 1)
		return Plugin_Continue;
	
	FirstToTalk npc = view_as<FirstToTalk>(victim);
	if(b_NpcIsInvulnerable[npc.index])
	{
		damage = 0.0;
	}
	else if(npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
	return Plugin_Changed;
}

void FirstToTalk_NPCDeath(int entity)
{
	FirstToTalk npc = view_as<FirstToTalk>(entity);
	if(!npc.m_bGib)
		npc.PlayDeathSound();
	
	SDKUnhook(npc.index, SDKHook_OnTakeDamage, FirstToTalk_TakeDamage);
	SDKUnhook(npc.index, SDKHook_Think, FirstToTalk_ClotThink);

	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
}