# TP - Mini-Projet supervision

## Table des matières

[TOC]

## Introduction

Le repository du projet est trouvable en cliquant sur [ce lien](https://github.com/Marc-Harony/23-813-BROISIN-ARAKHSIS)

## Partie I : mise en place d'une maquette de réseau local avec haute disponibilité

### Schéma du réseau :

![schema_reseau.png](./.attachments.3011/Schema_reseau.png)

### Étude théorique préparatoire

#### Question 1 - Combien de lignes dans la table de routage ?

Théoriquement, 32 routes via car 2 x 16 routes vers les réseau interne de nos collègue (il y a 16 binômes et 2 routeurs/binômes), deux routes directement connectées 10.250.0.0/24 (externe) et 10.200.1.0/24 (interne) et une route pour le management (192.168.170.0/23), soit un total de **35 routes**.

##### Table de routage R1

| Réseau de destination | Prochain saut | Coût |
|-----------------------|:-------------:|-----:|
| 10\.200.1.0/24 | Directement connectée | \* |
| 10\.250.0.0/24 | Directement connectée | \* |
| 192\.168.170.0/23 | Directement connectée | \* |
| 10\.200.2.0/24 | 10\.250.0.103 (R1_Binôme2) | 1 |
| 10\.200.2.0/24 | 10\.250.0.104 (R2_Binôme2) | 1 |
| 0\.0.0.0/0 | 10\.250.0.253 | \* |
| 0\.0.0.0/0 | 10\.250.0.254 | \* |

##### Table de routage R2

| Réseau de destination | Prochain saut | Coût |
|-----------------------|:-------------:|-----:|
| 10\.200.1.0/24 | Directement connectée | \* |
| 10\.250.0.0/24 | Directement connectée | \* |
| 192\.168.170.0/23 | Directement connectée | \* |
| 10\.200.2.0/24 | 10\.250.0.103 (R1_Binôme2) | 1 |
| 10\.200.2.0/24 | 10\.250.0.104 (R2_Binôme2) | 1 |
| 0\.0.0.0/0 | 10\.250.0.253 | \* |
| 0\.0.0.0/0 | 10\.250.0.254 | \* |

Dans ces tables, on a les 3 routes directement connectées, 2 routes récupérées avec OSPF et enfin les 2 routes par défaut.

#### Question 2 - Rôle de VRRP (Virtual Router Redundancy Protocol)

Le protocole de redondance de routeur virtuel, VRRP, est un protocole qui a pour but d'augmenter la haute disponibilité de la passerelle par défaut dans un LAN, de sorte que, lors de la défaillance du routeur principal, un routeur de secours puisse prendre le relais pour router les paquets du LAN vers l'extérieur et ce de manière invisible pour les machines du LAN.

#### Question 3 - Fonctionnement général de VRRP

Voici comment fonctionne le protocole VRRP : 

On dispose de deux ou plusieurs routeurs qui accedent au LAN et aux autres réseaux sur lesquels les paquets du LAN doivent sortir.

On choisit les routeurs que l'on souhaite utiliser pour configurer une passerelle et on les configures avec les parametres suivants : 

- Un numéros de groupe VRID


- Une prioritée codée sur un octet (avec une valeur comprise entre 1 et 254)
- Une adresse IP virtuelle commune pour tous. 

A l'aide de ces informations les routeurs du groupes vont définir une adresse mac virtuelle qui sera egale à **00-00-5E-00-01-{VRID}.**

Les routeurs comuniques entre eux a intervalle regulier via des message multicast sur l'dresse 224.0.0.18 et avec le champs protocole de l'en-tête ip a 0x112.

Ces messages servent a echanger entre eux leurs priorités, le routeur avec la plus hauite priorité passe maitre. En cas d'égalité de deux pritorité, le routeur avec l'adresse ip la plus "grande" (numériquement) passe maitre.

  
Le routeur maitre se présente au réseaux avec l'ip et la mac virtuelle. Les autres routeurs passe en mode backup, ils continues d'envoyer des paquet en multicast mais restent passive niveau routage pour le LAN.

Sur les machines du LAN on parametre la paserelle par défaut avec l'adresse virtuelle. Cette configuration est faite une seule fois (lors de la configuraation DHCP par exemple). Cela permet a ce que le chqgement de maitre soit invisible pour les équipement du LAN. et 

#### Question 4 - Rôle de OSPF dans la topologie

Dans notre cas, grâce au protocole OSPF on s'assure que les deux routeurs R1 et R2 possède les mêmes routes dans leurs table de routage. il faut en effet si l'un des routeurs tombe que l’autre soit en mesure d'acheminer les paquets du LAN vers les mêmes destination que le maitre.

#### Question 5 - Tests de fonctionnement

Pour valider la mise en place du réseau a la fin de la mise en place des VMs A et R1, nous allons tester les différents points suivants :

##### 1) Tests de connectivité

Vérifier la connectivité de A vers R1 :

```
A~# ping 10.200.1.251
```

Vérifier la connectivité de A vers R2 :

```
A~# ping 10.200.1.252
```

Vérifier la connectivité de R1 vers R2

```
R1~# ping 10.200.1.252
```

#### Question 6 - Tests de fonctionnement avec OSPF

On vérifie l'état de la table de routage des routeurs.

```
RX~# sh ip route
```

Si la configuration est fonctionnelle, on peut voir des routes avec le code O.

Vérifier que R1 reçoivent bien des routes OSPF:

```
 R1~# show ip route
813-R1(config-router)#do sh ip route
[...]
O*E2  0.0.0.0/0 [110/10] via 10.200.1.252, 00:00:06, GigabitEthernet2
      10.0.0.0/8 is variably subnetted, 18 subnets, 2 masks
O        10.20.3.1/32 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.20.3.2/32 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.20.4.2/32 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.20.5.1/32 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.20.5.2/32 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.100.1.0/24 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.100.3.0/24 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.100.4.0/24 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.100.5.0/24 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
C        10.200.1.0/24 is directly connected, GigabitEthernet2
L        10.200.1.251/32 is directly connected, GigabitEthernet2
O        10.200.2.0/24 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.200.3.0/24 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.200.4.0/24 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.200.5.0/24 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
O        10.200.6.0/24 [110/3] via 10.200.1.252, 00:00:06, GigabitEthernet2
C        10.250.0.0/24 is directly connected, GigabitEthernet3
L        10.250.0.101/32 is directly connected, GigabitEthernet3
      172.29.0.0/16 is variably subnetted, 2 subnets, 2 masks
C        172.29.253.0/24 is directly connected, GigabitEthernet1
L        172.29.253.32/32 is directly connected, GigabitEthernet1
      192.0.0.0/32 is subnetted, 1 subnets
C        192.0.0.1 is directly connected, Loopback0
O     192.168.140.0/23 [110/102] via 10.200.1.252, 00:00:06, GigabitEthernet2
O     192.168.176.0/24 [110/102] via 10.200.1.252, 00:00:06, GigabitEthernet2
```

Ici, la table de routage nous montre que R1 a bien reçu les routes des autres routeurs et qu'elles ont été apprises grâce à OSPF.

#### Question 7 - Configuration de VRRP:

```
R1~# interface GigabitEthernet2
R1~# vrrp 1 ip 10.200.1.254
R1~# vrrp 1 priority 110
R1~# exit

R2~# interface GigabitEthernet2
R2~# vrrp 1 ip 10.200.1.254
R2~# vrrp 1 priority 100
R2~# exit
```

Avec une priorité supérieure, R1 devient le routeur Maître et R2 le routeur de Backup.

#### Question 8 - Test global du réseau

Sur PC A réaliser un ping vers google.fr :

- Éteindre le routeur maitre (R1), vérifer le temps de bascule du routeur maitre de R1 vers R2, le ping doit continuer de passer.

  **Résultat :** Après avoir coupé le lien entre R1 et le LAN des machines A et B (10.200.1.0/24) on observe que B prend immédiatement le rôle de maître. Côté PC-A le ping n'est pas interrompu. Lorsque le lien est coupé, on remarque un saut dans les numéros de séquence des pings.
- Allumer R1, vérifier le temps de bascule du routeur maître de R2 vers R1, le ping doit continuer de passer.

  **Résultat :** Le routeur R1 a repris immédiatement le rôle de maitre. De la même manière, le temps de bascule est invisible pour le PC A ; seul est visible un saut dans les numéros de séquence de la même manière que pour le test précédent.
- Éteindre le lien entre le routeur maitre (R1) et le cœur de réseau (10.250.0.0/24), la route doit être redirigé vers le routeur R2.

  **Résultat :** Après une courte période de 1s sans connectivité, la VIP (**10\.200.1.254,** actuellement sur R1 car le routeur à toujours la plus haute priorité) va **redistribué** la route vers R2 (**10\.200.1.252**)

  ```bash
  64 octets de 8.8.8.8 : icmp_seq=10 ttl=114 temps=1036 ms
  64 octets de 8.8.8.8 : icmp_seq=11 ttl=114 temps=12.2 ms
  De 10.200.1.254 icmp_seq=18 Redirect Network(Nouveau sautsuivant : 10.200.1.252)
  64 octets de 8.8.8.8 : icmp_seq=18 ttl=114 temps=12.0 ms
  64 octets de 8.8.8.8 : icmp_seq=19 ttl=114 temps=13.5 ms
  ```

![image.png](.attachments.4982/image.png)

#### Question 9 - Configuration SNMPv3

```
Configuration : 
R1~# snmp-server location pm-serv16
R2~# snmp-server location pm-serv14
RX~# snmp-server contact Arakhsis-Broisin

Récupération sysLocation : 
A~# snmpget -v 3 -u snmpuser -l authPriv -a SHA -A auth_pass -x AES -X crypt_pass 10.200.1.251 1.3.6.1.2.1.1.6.0
```

#### Question 10 : Encodage utilisé par SNMP

Lors de l'émission de données SNMP, l'encodage utilisé est le BER (Basic Encoding Rules). Cet encodage est utilisé pour encoder les données SNMP en un format binaire qui peut être transmis sur le réseau.

<https://prod.liveshare.vsengsaas.visualstudio.com/join?796A96237B3BEF8DE061449F9CBD9A9A0D18>

#### Question 11 - Analyse de trame SNMPv2

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla nec purus feugiat, molestie ipsum et, consequat nunc

#### Question 12 - OID branche VRRP

`::= { mib-2 68 }`


#### Configuration de SNMPv2
```bash
Configuration de SNMPv2
RX~# snmp-server community 123test123 RO

Test de configuration de SNMPv2
A~# snmpwalk -v 2c -c 123test123 10.200.2.X system
```

#### Question 13 - Pourquoi la première commande échoue alors que la deuxième réussie ?

Par defaut, la MIB VRRP n'est pas intallée. Nous pouvoins la trouver dans /usr/share/snmp/mibs/.


#### Question 14 - OID par rapport à mib-2 de la table vrrpOperTable. Relever dans la vrrpOperTable de R1 et expliquer les 8 premières colonnes et comment est constitué l’index.


Dans le fichier `VRRP-MIB`, on trouve :

`vrrpMIB ::= { mib-2 68 }`
`vrrpOperations ::= { vrrpMIB 1 }`
`vrrpOperTable ::= { vrrpOperations 3 }`

On peut donc en déduire son OID : `mib-2.68.1.3`

| Champ | Description |
|---|---|
| vrrpOperVirtualMacAddr | Adresse MAC virtuelle de la VRRP |
| vrrpOperState | Etat de la VRRP |
| vrrpOperAdminState | Etat administratif de la VRRP |
| vrrpOperPriority | Priorité de la VRRP |
| vrrpOperIpAddrCount | Nombre d'adresses IP |
| vrrpOperMasterIpAddr | Adresse IP du `master` |
| vrrpOperPrimaryIpAddr | Adresse IP primaire |
| vrrpOperAuthType | Type d'authentification |

D'après la MIB on a: `INDEX { ifIndex, vrrpOperVrId }`.

L'inex est constitué de l'index de l'interface et de l'ID de la VRRP.

