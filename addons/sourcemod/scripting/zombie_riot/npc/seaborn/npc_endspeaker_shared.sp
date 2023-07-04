#pragma semicolon 1
#pragma newdecls required
 
static const char LargeDeath[][] =
{
	"npc/antlion_guard/antlion_guard_die1.wav",
	"npc/antlion_guard/antlion_guard_die2.wav"
};

static const char LargeAnger[][] =
{
	"npc/antlion_guard/angry1.wav",
	"npc/antlion_guard/angry2.wav",
	"npc/antlion_guard/angry3.wav"
};

static const char LargeMeleeHit[][] =
{
	"npc/antlion_guard/shove1.wav"
};

static const char NormalAttack[][] =
{
	"npc/antlion/attack_single1.wav",
	"npc/antlion/attack_single2.wav",
	"npc/antlion/attack_single3.wav"
};

static const char NormalHurt[][] =
{
	"npc/antlion/pain1.wav",
	"npc/antlion/pain2.wav"
};

static const char SmallHurt[][] =
{
	"npc/headcrab_poison/ph_talk1.wav",
	"npc/headcrab_poison/ph_talk2.wav",
	"npc/headcrab_poison/ph_talk3.wav"
};

static const char SmallAttack[][] =
{
	"npc/headcrab_poison/ph_jump1.wav",
	"npc/headcrab_poison/ph_jump2.wav",
	"npc/headcrab_poison/ph_jump3.wav"
};

static const char DigDown[] = "npc/antlion/digdown1.wav";
static const char DigUp[] = "npc/antlion/digup1.wav";
static const char GrabBuff[] = "npc/antlion/land1.wav";

void EndSpeaker_MapStart()
{
	PrecacheSoundArray(LargeDeath);
	PrecacheSoundArray(LargeAnger);
	PrecacheSoundArray(LargeMeleeHit);
	PrecacheSoundArray(NormalAttack);
	PrecacheSoundArray(NormalHurt);
	PrecacheSoundArray(SmallHurt);
	PrecacheSoundArray(SmallAttack);
	PrecacheSound(DigDown);
	PrecacheSound(DigUp);
	PrecacheSound(GrabBuff);
	
	PrecacheModel("models/headcrabclassic.mdl");
	PrecacheModel("models/antlion.mdl");
	PrecacheModel("models/antlion_guard.mdl");
}

#define BUFF_FOUNDER		(1 << 0)
#define BUFF_PREDATOR		(1 << 1)
#define BUFF_BRANDGUIDER	(1 << 2)
#define BUFF_SPEWER		(1 << 3)
#define BUFF_SWARMCALLER	(1 << 4)
#define BUFF_REEFBREAKER	(1 << 5)

static bool HardMode;
static int FreeplayStage;
static int BaseHealth;
static float SpawnPos[3];
static float SpawnAng[3];

methodmap EndSpeaker < CClotBody
{
	public void PlayDeathSound() 
	{
		EmitSoundToAll(DigDown[GetRandomInt(0, sizeof(DigDown) - 1)], this.index, SNDCHAN_STATIC, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlaySpawnSound() 
	{
		EmitSoundToAll(DigUp[GetRandomInt(0, sizeof(DigUp) - 1)], this.index, SNDCHAN_STATIC, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public EndSpeaker(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		FreeplayStage++;
		switch(FreeplayStage)
		{
			case 2:
			{
				return view_as<EndSpeaker>(EndSpeaker2(ally));
			}
			case 3:
			{
				return view_as<EndSpeaker>(EndSpeaker3(ally));
			}
			case 4:
			{
				return view_as<EndSpeaker>(EndSpeaker4(ally));
			}
		}
		
		FreeplayStage = 1;
		return view_as<EndSpeaker>(EndSpeaker1(client, vecPos, vecAng, ally, "Elite"));
	}
	public void GetSpawn(float pos[3], float ang[3])
	{
		pos[0] = SpawnPos[0];
		pos[1] = SpawnPos[1];
		pos[2] = SpawnPos[2];

		ang[0] = SpawnAng[0];
		ang[1] = SpawnAng[1];
		ang[2] = SpawnAng[2];
	}
	public void SetSpawn(const float pos[3], const float ang[3])
	{
		SpawnPos[0] = pos[0];
		SpawnPos[1] = pos[1];
		SpawnPos[2] = pos[2];

		SpawnAng[0] = ang[0];
		SpawnAng[1] = ang[1];
		SpawnAng[2] = ang[2];
	}
	public float Attack(float gameTime)
	{
		if(!(this.m_hBuffs & BUFF_REEFBREAKER))
			return 1.0;

		if(this.m_flStackDecayAt < gameTime)
		{
			// Every second decreases by 1 after 2.5 seconds
			this.m_iAttackStack -= 1 + RoundToFloor(gameTime - this.m_flStackDecayAt);
			if(this.m_iAttackStack < 0)
				this.m_iAttackStack = 0;
		}

		float multi = 1.0 + (this.m_iAttackStack * 0.08);

		if(++this.m_iAttackStack > 20)
			this.m_iAttackStack = 20;
		
		this.m_flStackDecayAt = gameTime + 3.5;

		return multi;
	}
	public void EatBuffs()
	{
		this.m_hBuffs = 0;
		this.m_iAttackStack = 0;
		this.m_flStackDecayAt = FAR_FUTURE;
		this.m_bIgnoreBuildings = false;
		KillFeed_SetKillIcon(this.index, "crocodile");

		int count;
		int[] remain = new int[i_MaxcountNpc_Allied];

		for(int i; i < i_MaxcountNpc_Allied; i++)
		{
			int entity = EntRefToEntIndex(i_ObjectsNpcs_Allied[i]);
			if(entity != INVALID_ENT_REFERENCE && i_NpcInternalId[entity] == REMAINS && IsEntityAlive(entity))
			{
				remain[count++] = entity;
			}
		}

		float vecTarget[3], vecOther[3];

		int hunger = this.m_bHardMode ? 2 : 1;
		for(int a; a < hunger; a++)
		{
			float distance = FAR_FUTURE;
			int entity;

			for(int b; b < count; b++)
			{
				vecTarget = WorldSpaceCenter(remain[b]);

				float dist = GetVectorDistance(SpawnPos, vecTarget, true);
				if(dist < distance)
				{
					entity = remain[b];
					distance = dist;
				}

			}

			if(entity)
			{
				vecTarget = WorldSpaceCenter(entity);

				for(int b; b < count; b++)
				{
					vecOther = WorldSpaceCenter(remain[b]);

					if(remain[b] != entity)
					{
						float dist = GetVectorDistance(vecTarget, vecOther, true);
						if(dist > 62500.0)	// 250 HU
							continue;
					}

					this.m_hBuffs |= view_as<Remains>(remain[b]).m_iBuffType;
					ParticleEffectAt(vecOther, "water_bulletsplash01", 3.0);
					spawnRing_Vectors(vecOther, 500.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 255, 50, 50, 200, 1, 2.0, 6.0, 0.1, 1);
				}

				i_ExplosiveProjectileHexArray[this.index] = EP_DEALS_DROWN_DAMAGE;
				Explode_Logic_Custom(999999.9, -1, this.index, -1, vecTarget, 500.0, _, _, true, _, false, _, EndSpeaker_EatPost);
				EmitSoundToAll(GrabBuff[GetRandomInt(0, sizeof(GrabBuff) - 1)], entity, SNDCHAN_STATIC, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
			}
		}

		for(int i; i < count; i++)
		{
			SDKHooks_TakeDamage(remain[i], 0, 0, 99999999.9, DMG_DROWN);
		}

		vecTarget = WorldSpaceCenter(this.index);
		vecTarget[2] += 80.0;

		if(this.m_hBuffs & BUFF_FOUNDER)
		{
			this.m_flRangedArmor *= 0.4;

			this.m_iWearable1 = ParticleEffectAt(vecTarget, "powerup_icon_resist", -1.0);
			SetParent(this.index, this.m_iWearable1);
			vecTarget[2] += 20.0;
		}

		if(this.m_hBuffs & BUFF_PREDATOR)
		{
			this.m_iWearable2 = ParticleEffectAt(vecTarget, "powerup_icon_reflect", -1.0);
			SetParent(this.index, this.m_iWearable2);
			vecTarget[2] += 20.0;
		}

		if(this.m_hBuffs & BUFF_BRANDGUIDER)
		{
			this.m_iWearable3 = ParticleEffectAt(vecTarget, "powerup_icon_king", -1.0);
			SetParent(this.index, this.m_iWearable3);
			vecTarget[2] += 20.0;
		}

		if(this.m_hBuffs & BUFF_SPEWER)
		{
			this.m_iWearable4 = ParticleEffectAt(vecTarget, "powerup_icon_precision", -1.0);
			SetParent(this.index, this.m_iWearable4);
			vecTarget[2] += 20.0;
		}

		if(this.m_hBuffs & BUFF_SWARMCALLER)
		{
			b_CannotBeSlowed[this.index] = true;
			this.m_bThisNpcIsABoss = true;

			this.m_iWearable5 = ParticleEffectAt(vecTarget, "powerup_icon_agility", -1.0);
			SetParent(this.index, this.m_iWearable5);
			vecTarget[2] += 20.0;
		}

		if(this.m_hBuffs & BUFF_REEFBREAKER)
		{
			this.m_iWearable6 = ParticleEffectAt(vecTarget, "powerup_icon_strength", -1.0);
			SetParent(this.index, this.m_iWearable6);
			vecTarget[2] += 20.0;
		}
	}

	property float m_flStackDecayAt
	{
		public get()
		{
			return this.m_flGrappleCooldown;
		}
		public set(float value)
		{
			this.m_flGrappleCooldown = value;
		}
	}
	property int m_iAttackStack
	{
		public get()
		{
			return this.m_iOverlordComboAttack;
		}
		public set(int value)
		{
			this.m_iOverlordComboAttack = value;
		}
	}
	property int m_hBuffs
	{
		public get()
		{
			return this.g_TimesSummoned;
		}
		public set(int value)
		{
			this.g_TimesSummoned = value;
		}
	}
	property int m_iBaseHealth
	{
		public get()
		{
			return BaseHealth;
		}
		public set(int value)
		{
			BaseHealth = value;
		}
	}
	property bool m_bIgnoreBuildings
	{
		public get()
		{
			return this.Anger;
		}
		public set(bool value)
		{
			this.Anger = value;
		}
	}
	property bool m_bHardMode
	{
		public get()
		{
			return HardMode;
		}
		public set(bool value)
		{
			HardMode = value;
		}
	}
}

public void EndSpeaker_EatPost(int attacker, int victim, float damage, int weapon)
{
	if(i_NpcInternalId[victim] == CITIZEN)
	{
		// Eaten
		view_as<Citizen>(victim).SetDowned(2);
	}
}

methodmap EndSpeakerLarge < EndSpeaker
{
	public void PlayDeathSound() 
	{
		EmitSoundToAll(LargeDeath[GetRandomInt(0, sizeof(LargeDeath) - 1)], this.index, SNDCHAN_STATIC, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayMeleeSound()
 	{
		EmitSoundToAll(LargeAnger[GetRandomInt(0, sizeof(LargeAnger) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayMeleeHitSound()
	{
		EmitSoundToAll(LargeMeleeHit[GetRandomInt(0, sizeof(LargeMeleeHit) - 1)], this.index, SNDCHAN_STATIC, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);	
	}
}

methodmap EndSpeakerNormal < EndSpeaker
{
	public void PlayMeleeSound()
 	{
		EmitSoundToAll(NormalAttack[GetRandomInt(0, sizeof(NormalAttack) - 1)], this.index, SNDCHAN_STATIC, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayHurtSound()
	{
		EmitSoundToAll(NormalHurt[GetRandomInt(0, sizeof(NormalHurt) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);	
	}
}

methodmap EndSpeakerSmall < EndSpeaker
{
	public void PlayMeleeSound()
 	{
		EmitSoundToAll(SmallAttack[GetRandomInt(0, sizeof(SmallAttack) - 1)], this.index, SNDCHAN_STATIC, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayHurtSound()
	{
		EmitSoundToAll(SmallHurt[GetRandomInt(0, sizeof(SmallHurt) - 1)], this.index, SNDCHAN_VOICE, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);	
	}
}

public Action EndSpeaker_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker < 1)
		return Plugin_Continue;
	
	EndSpeaker npc = view_as<EndSpeaker>(victim);
	float gameTime = GetGameTime(npc.index);

	static int Pity;
	if((npc.m_hBuffs & BUFF_PREDATOR) && Pity < (NpcStats_IsEnemySilenced(npc.index) ? 2 : 6) && npc.m_flNextDelayTime <= (gameTime + DEFAULT_UPDATE_DELAY_FLOAT) && (GetURandomInt() % 2))
	{
		damage = 0.0;
		Pity++;
	}
	else if(npc.m_flHeadshotCooldown < gameTime)
	{
		npc.m_flHeadshotCooldown = gameTime + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
		Pity = 0;
	}
	
	if(!npc.m_bIgnoreBuildings && (npc.m_hBuffs & BUFF_BRANDGUIDER) && !NpcStats_IsEnemySilenced(npc.index))
	{
		int maxhealth = GetEntProp(npc.index, Prop_Data, "m_iMaxHealth");
		int health = GetEntProp(npc.index, Prop_Data, "m_iHealth");

		if(health < (maxhealth * 2 / 5))
		{
			npc.m_flMeleeArmor /= 4.0;
			npc.m_bIgnoreBuildings = true;
			Change_Npc_Collision(npc.index, 1);	// Ignore buildings
		}
	}
	return Plugin_Changed;
}

public void EndSpeaker_BurrowAnim(const char[] output, int caller, int activator, float delay)
{
	RemoveEntity(caller);
}