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

*VRRP* orchestre la redondance en attribuant une adresse IP commune à un groupe de routeurs, avec un routeur principal répondant aux requêtes. En cas de défaillance de ce dernier, un routeur de secours prend le relais sans interruption de service, assurant une connectivité réseau fiable et constante.

#### Question 3 - Fonctionnement général de VRRP

1. **Configuration des Routeurs**: Plusieurs routeurs sont configurés dans un groupe VRRP. Un de ces routeurs est désigné comme le routeur principal (*Master*), tandis que les autres sont des routeurs de secours (*Backup*). Ils partagent une adresse IP virtuelle, qui est l'adresse utilisée par les machines du réseau pour acheminer leur trafic.
2. **Élection du Routeur Principal**: L'élection du routeur principal se fait selon la priorité configurée sur chaque routeur. Le routeur avec la plus haute priorité devient le principal. En cas d'égalité, l'adresse IP la plus élevée est utilisée comme critère de sélection.
3. **Surveillance de l'État**: Le routeur principal envoie régulièrement des messages de type "*advertisement*" pour indiquer qu'il est en fonction. Les routeurs de secours écoutent ces messages pour déterminer si le routeur principal est toujours opérationnel.
4. **Basculement en Cas de Défaillance**: Si les routeurs de secours cessent de recevoir des messages du routeur principal pendant un certain temps (délai déterminé par la configuration), ils supposent que le routeur principal a échoué. Le routeur de secours avec la priorité la plus élevée devient alors le nouveau routeur principal.
5. **Reprise du Routeur Défaillant**: Lorsque le routeur principal initial se remet en ligne après une défaillance, il peut reprendre son rôle de routeur principal ou rester en tant que routeur de secours, selon la configuration (notamment l'option de préemption).
6. **Utilisation par les Machines A et B**: Les machines sur le réseau local, telles que A et B, configurées pour utiliser l'adresse IP virtuelle comme passerelle par défaut, continuent de fonctionner normalement sans interruption, même si le routeur principal change, car l'adresse IP virtuelle reste constante.

Les machines A et B seront configurées avec pour passerelle l'adresse *IP* virtuelle de notre cluster de routeur, ils ne verront pas la coupure en cas de défaillance car ils enverront leur paquets toujours à la même *IP*, seulement l'adresse *MAC* sera changée dans leur table *ARP* mais ceci est invisible pour l'utilisateur.

Lorsqu'un routeur *backup* devient défaillant alors le *master* reste tel quel et reçoit les paquets. Si le *master* tombe alors le routeur *backup* devient actif. Dans le cas où il y aurait plusieurs routeurs *bakcup*, c'est le routeur qui possède la plus haute priorité qui devient le routeur *master.* Cette solution ne permet pas le load-balancing mais permet tout de même un certain niveau de redondance.

Par defaut un paquet contenant des message *VRRP* est echangé en *multicast* toute les secondes (*ethertype* **112**). Dans ces message il est indiqué la priorité du *master*, si la priorité du *master* est superieure à celle des routeurs *backup,* il reste passif. À défaut de message d'un autre routeur *master* dans le sous-réseau (après 3,6 s par défaut), un routeur *backup* se proclamera *master*.

#### Question 4 - Rôle de OSPF dans la topologie

OSPF (Open Shortest Path First) est un protocole de routage dynamique qui détermine automatiquement le chemin le plus efficace pour les données à travers un réseau. Contrairement au routage statique, qui requiert une configuration manuelle et ne s'adapte pas aux changements de réseau, OSPF ajuste les itinéraires en temps réel, améliorant la haute disponibilité et la redondance. Cette approche élimine la nécessité de saisir les routes à la main, réduisant les erreurs de configuration et simplifiant la maintenance du réseau.

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
- Allumer R1, vérifer le temps de bascule du routeur maître de R2 vers R1, le ping doit continuer de passer.

  **Résultat :** Le routeur R1 a repris immédiatement le rôle de maûtre. De la même manière, le temps de bascule est invisible pour le PC A ; seul est visible un saut dans les numéros de séquence de la même manière que pour le test précédent.
