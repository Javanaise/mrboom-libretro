;    _________   _________     _________   _________   _________   _________
; ___\______ /___\____   /_____\____   /___\_____  /___\_____  /___\______ /___
; \_   |   |   _     |_____/\_   ____    _     |/    _     |/    _   |   |   _/
;  |___|___|___|_____|  sns  |___________|___________|___________|___|___|___|
;==[mr.boom 3.0]=====================================================[1997-99]=
; ? tapis roulants nivo 1
; ? fleches sur le sol pour les bombes kon pousse

%MACS

;NB_JOUEURS_MIN EQU 1
duree_saut EQU 64
duree_mort EQU 32
;ttp  EQU 4000 ;emps avant le mode demo (touches pressees ...)
;ttp  EQU 40 ;emps avant le mode demo (touches pressees ...)

ttp2 EQU 180  ;temps avant le mode demo (pas de touches pressees)
TRICHE EQU 0

;faire des apocalypse differentes
;version_du_jeu EQU 00110000B ;10110000B
nombre_de_vbl_avant_le_droit_de_poser_bombe2 EQU 60*2
invisibilite_totale EQU 100 ;nombre de résistance apres un choc.
invinsibilite_bonus equ 750 ;nombre vbl de mégaforce apres manger bonus...

duree_match EQU 512 ;001000000000B  ;2 minutes
duree_match2 EQU 48 ; 000000110000B ;30 secondes
duree_match4 EQU 512 ;001000000000B ;2 minutes
duree_match3 EQU 256 ;000100000000B ;1 minutes
duree_match5 EQU 304 ; 000100110000B ;1 minutes 30

;+duree_match EQU 512 ;001000000000B  ;2 minutes^M
;+duree_match2 EQU 48 ; 000000110000B ;30 secondes^M
;+duree_match4 EQU 512 ;001000000000B ;2 minutes^M
;+duree_match3 EQU 256 ;000100000000B ;1 minutes^M
;+duree_match5 EQU 304 ; 000100110000B ;1 minutes 30^M

;010011B  ;001100000000B
time_bouboule equ 5 ;temps pour rotation boules menu
pic_max equ 420 ;durée attente sur gfx de zaac
duree_conta EQU 0800 ;nombre de vbl pour une contamination.


duree_draw2 EQU 500 ;durée du draw game
duree_med2 EQU  1200 ;durée du med cere ;10 secondes...
duree_vic2 EQU  1200 ;durée du vic cere
attente_avant_draw2 equ 100
attente_avant_med2 equ 100
temps_re_menu equ 15
resistance_au_debut_pour_un_dyna equ   0
;----- pour les joueurs...
info1 equ 1
info2 equ 1
info3 equ 210
info4 equ 3
;1,2,3 (normal),4:double...

;ééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééé
; PMODE/W Assembly Example File #1
;ééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééé
.386p


;
;extrn     ExitProcess     : PROC     ;procedure to shut down a process
;
;extrn     ShowWindow      : PROC
;extrn     GetModuleHandleA: PROC
;extrn     GetForegroundWindow : PROC

;extrn     ExitProcess     : PROC     ;procedure to shut down a process
;extrn     GetForegroundWindow : PROC
;extrn     SendMessageA    : PROC
;extrn     IsZoomed        : PROC
;extrn     ShowWindow      : PROC



vbl MACRO
local avbl1
local avbl2
inc dword ptr [changement]
mov     dx,3dah
avbl1:           in      al,dx
test    al,8
jne     avbl1
avbl2:           in      al,dx
test    al,8
je      avbl2
xor eax,eax
xor edx,edx
ENDM

BIGENDIANPATCH MACRO a
local blablablatoto
cmp isbigendian,1
jne blablablatoto
mov bigendianin,a
push eax
mov al,byte ptr [bigendianin]
mov byte ptr [bigendianout+3],al
mov al,byte ptr [bigendianin+1]
mov byte ptr [bigendianout+2],al
mov al,byte ptr [bigendianin+2]
mov byte ptr [bigendianout+1],al
mov al,byte ptr [bigendianin+3]
mov byte ptr [bigendianout+0],al
pop eax
mov a,bigendianout
blablablatoto:
ENDM

PUSHALL MACRO     ; Pushes all registers onto stack = 18c
PUSHAD
PUSH DS ES
ENDM

POPALL MACRO      ; Pops all registers from stack = 18c
POP ES DS
POPAD
ENDM


actionButtonPushed2 MACRO a
local ok
cmp byte ptr [total_t+ebx+4],1
je ok
cmp byte ptr [total_t+ebx+5],1
je ok
cmp byte ptr [total_t+ebx+6],1
je ok
jmp a
ok:
endm

actionButtonPushed MACRO a
local ok
cmp byte ptr [esi+4],1
je ok
cmp byte ptr [esi+5],1
je ok
cmp byte ptr [esi+6],1
je ok
jmp a
ok:
endm


_TEXT   segment use32 dword public 'CODE' ;IGNORE
        assume  cs:_TEXT,ds:_DATA

start: ;IGNORE

        jmp _main

        db '  Monsieur Boom  '   ; The "WATCOM" string is needed in
                                        ; order to run under DOS/4G and WD.

;E db 'envois !!!',10,13,'$'
;a db 'attend... !!!',10,13,'$'


get_all_infos3 MACRO
local donoterasekeyslabel
cmp taille_exe_gonfle,0
je donoterasekeyslabel
PUSHALL
;------------- ;ordy local...
push ds
pop  es
mov esi,offset donnee2
mov edi,offset total_t
mov ecx,touches_size
rep movsb
POPALL
donoterasekeyslabel:
ENDM

get_all_infos2 MACRO
local donoterasekeyslabel
cmp taille_exe_gonfle,0
je donoterasekeyslabel
PUSHALL
;------------- ;ordy local...
push ds
pop  es
mov esi,offset donnee2
mov edi,offset total_t
mov ecx,touches_size
rep movsb
;------------------
;edi est bien placé...
POPALL
donoterasekeyslabel:
ENDM




num proc near ;entree eax:juska 9999999999
push dx esi
push ebx eax ecx

;mov eax,0543212345

mov ebx,eax

mov esi,offset liste_de_machin
mov ecx,[esi]
errrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr:
mov ax,0
rrtetrertertretertterert:
cmp ebx,ecx ;10000
jb reerrereerret
sub ebx,ecx ;10000
inc ax
jmp rrtetrertertretertterert
reerrereerret:
;affchiffre
push ax
push dx
add al,48
mov dl,al
mov ah,2
int 21h
pop ax
pop dx


add esi,4
mov ecx,[esi]
or ecx,ecx
jz reererreer
jmp errrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
reererreer:

mov dl,' '
mov ah,2
int 21h

pop ecx eax ebx
pop esi dx
ret
endp

;

;----- aff hexa.
;notreadresse db 4 dup (0FFh) ;netadd
;             db 6 dup (0FFh) ;nodeadd
;             dw 0FFFFh       ;sockette...

aff_adresse proc near  ; ds:si sur adresse
push ds es
Pushad

mov cx,10
dds:
call hexa

cmp cx,1
je ertertertertert

mov dl,'.'

cmp cx,9
jne reterertert
mov dl,' '
reterertert:

cmp cx,3
jne reterertertu
mov dl,' '
reterertertu:


mov ah,2
int 21h
loop dds
ertertertertert:


mov dl,10
mov ah,2
int 21h
mov dl,13
mov ah,2
int 21h


popad
pop es ds
ret
aff_adresse endp

hexa proc near ; ds:si sur variable

xor ax,ax
lodsb
push ax
shr ax,4
movzx ebx,ax
mov dl,cs:[trucs+ebx]
mov ah,2
int 21h

pop ax
and al,01111B
movzx ebx,ax
mov dl,cs:[trucs+ebx]
mov ah,2
int 21h

ret
hexa endp

printeax proc near

;-----------------------
; convert the value in EAX to hexadecimal ASCIIs
;-----------------------
mov edi,OFFSET ASCII ; get the offset address
mov cl,8            ; number of ASCII
P1: rol eax,4           ; 1 Nibble (start with highest byte)
mov bl,al
and bl,0Fh          ; only low-Nibble
add bl,30h          ; convert to ASCII
cmp bl,39h          ; above 9?
jna short P2
add bl,7            ; "A" to "F"
P2: mov [edi],bl         ; store ASCII in buffer
inc edi              ; increase target address
dec cl              ; decrease loop counter
jnz P1              ; jump if cl is not equal 0 (zeroflag is not set)
;-----------------------
; Print string
;-----------------------
mov edx,OFFSET ASCII ; DOS 1+ WRITE STRING TO STANDARD OUTPUT
mov ah,9            ; DS:DX->'$'-terminated string
int 21h             ; maybe redirected under DOS 2+ for output to file
; (using pipe character">") or output to printer
ret
endp

last_color proc near

PUSHALL
;------------
;dans BX: la couleur k'on veut !!!
;mov bl,0100B ;rouge
;mov bh,10000000B ;indique clignotement
push bx
;mov ax,0b800h
;mov es,ax
;mov ds,ax
push ds
pop es

mov edi,0b8000h
mov esi,0b8000h
;xor di,di
;xor si,si
;-----
mov ah,03h
mov bh,0
int 10h
;dans dh ligne du curseur
dec dh ; car toujours > 1 vu k'on balance apres avoir afficvhé

;movzx edx,dh ;*128
shr dx,8
and edx,255
mov eax,edx
shl edx,7
shl eax,5
add edx,eax
add esi,edx
add edi,edx
mov cx,80
pop bx

nooon:
inc edi
inc esi

lodsb
or al,bh
and al,11110000B
or  al,bl
stosb
dec cx
jne nooon
;---------------------------------
POPALL
ret
last_color endp


;sortie: ebx entree ebp...
direction_du_joueur MACRO a
local trrtertyrtytyrtyrrtyRz
local trrtertyrtytyrtyrrtyRzt
local ytrrtertyrtytyrtyrrtyy
local ytrrtertyrtytyrtyrrtyRy
push eax
  xor ebx,ebx
  mov eax,[touches+ebp]
  and eax,127
  cmp eax,16
  jne trrtertyrtytyrtyrrtyRz
  mov ebx,-1*a
  trrtertyrtytyrtyrrtyRz:
  cmp eax,8
  jne trrtertyrtytyrtyrrtyRzt
  mov ebx,1*a
  trrtertyrtytyrtyrrtyRzt:
  cmp eax,00
  jne ytrrtertyrtytyrtyrrtyy
  mov ebx,32*a
  ytrrtertyrtytyrtyrrtyy:
  cmp eax,24
  jne ytrrtertyrtytyrtyrrtyRy
  mov ebx,-32*a
  ytrrtertyrtytyrtyrrtyRy:
pop eax
ENDM


;esi: endroit ou on pose la bombe...
;edi: infojoueur du dyna

pose_une_bombe MACRO
local vania
local ttyrrtyrtyrtyrtytyrrtyrtyyrtrty
local erertertrteterert
local nononono_onest_en_recordplay
mov byte ptr [esi],1

;utilise Esi par rapport a truc2 pour gauche/droite.
bruit2 11,34 ;,BLOW_WHAT2 ;bruit de kan on pose une bombe

;"hazard" pour ke les bombes soit pas toutes pareille lors du tri bombe
push eax
mov eax,dword ptr [edi] ;nombre de bombes k'on peut encore poser...
and eax,011B
add byte ptr [esi],al
pop eax
;---------------

dec dword ptr [edi] ;nombre de bombes k'on peut encore poser...

;donnee dw 20,20,277,277,150,200,250,280  ;x du dynablaster
;       dw 9,170,9,170,78,98,98,10 ;y du dynablaster

;liste_bombe dd 0 ; nombre de bombes...
;            dd 247 dup (0,0,0,0)
;1er: offset de l'infojoeur
;2eme: nombre de tours avant que ca PETE !!!
;3eme:distance par rapport au debut de truc2
;4eme puissance de la bombe. + retardee ou non

;mov ebx,[liste_bombe]
;shl ebx,4 ;*16

;recherche la premiere place de libre !!!
xor ebx,ebx
ttyrrtyrtyrtyrtytyrrtyrtyyrtrty:
cmp dword ptr [liste_bombe+ebx+4+1*4],0 ;indique emplacement non remplis !!!
je erertertrteterert
add ebx,taille_dune_info_bombe
jmp ttyrrtyrtyrtyrtytyrrtyrtyyrtrty
erertertrteterert:

mov edx,dword ptr [edi+4]        ;récupere la puissance de la bombe dans
                                 ;l'info du joueur...
mov ecx,dword ptr [edi+8]        ;récupere la taille de la meiche de la
                                 ;bombe dans l'info du joueur...

;mov [nomonster],1
  cmp action_replay,0
  jne nononono_onest_en_recordplay
cmp twice,1
jne nononono_onest_en_recordplay
shr ecx,1
nononono_onest_en_recordplay:

mov [liste_bombe+ebx+4+2*4],eax  ;distance par rapport au debut de truc2
mov word ptr [liste_bombe+ebx+4+3*4],dx  ;puissance de la bombe.
;------------------------------------ mouvement de la bombe
;truc_X   db 32*0,0,0,0,0,0,0,0,0,0,0,0,0 ;+ ou -...
;truc_Y   db 32*0,0,0,0,0,0,0,0,0,0,0,0,0

mov byte ptr [truc_X+eax],0
mov byte ptr [truc_Y+eax],0

mov word ptr [liste_bombe+ebx+4+4*4],0 ;!!!!!!!!!1 ;adder X automatique.
mov word ptr [liste_bombe+ebx+4+4*4+2],0
mov word ptr [liste_bombe+ebx+4+5*4],0   ;adder X
mov word ptr [liste_bombe+ebx+4+5*4+2],0 ;adder Y

;-------------------------------------------------


push ebx
mov ebx,[infojoueur+ebp] ;uniquement s'il y a droit...
mov edx,dword ptr [ebx+4*4]
pop ebx

;---- maladie de la bonbinette ???
cmp word ptr [maladie+ebp],6 ;malade ??? (en general)
jne vania
mov word ptr [liste_bombe+ebx+4+3*4],1  ;puissance de la bombe.
vania:
;------

mov word ptr [liste_bombe+ebx+4+3*4+2],dx  ;bombe a retardement ou pas ???

mov [liste_bombe+ebx+4+1*4],ecx  ;nombre de tours avant que ca PETE !!!
mov [liste_bombe+ebx+4+0*4],edi  ;offset de l'infojoeur
inc dword ptr [liste_bombe]
mov [tribombe2+ebp],0


ENDM

lapinomb MACRO a
local nooooiii
local nooooiii2
local nan_prend_pas_lombre

cmp word ptr [donnee4+4+ebx],-1
je nooooiii2

push ecx ebx
mov ecx,edi
add ecx,ecx
mov ebx,[kel_ombre]
shr ebx,cl
and ebx,1111B
jz nan_prend_pas_lombre
cmp ebx,3
ja nan_prend_pas_lombre
pop ebx ecx
;ombres      dw 8 dup (0)
;mov ax,[ombres+edi]
;push ecx ebx
;sub ecx
mov a,[ombres+edi]
add a,8*320
jmp nooooiii
nan_prend_pas_lombre:
pop ebx ecx
nooooiii:
;ca c pour lordre daffichage, pour pas ke 2 dyna se croisent de maniere bizarre
add a,bx
add a,bx
add a,bx
nooooiii2:
ENDM

poussage MACRO ou,xy_adder,xy_x32
local pas_changement_case
local pas_ca___
local stooppppes
local continue_lme_train_train
local stooppppes_pas
local ya_une_bombe_stope_ou_explose
local ttyrrtyrtyrtyrtytyrrtyrtyyrtrty
local nan_pas_de_bombe_ayant_squatte_entre_temps
local erertertrteterert
local fait_pas_peter
local tantpis
local nanana
local reterertertertertterertert
push ebx eax
xor eax,eax
cmp word ptr [liste_bombe+ebp+4+4*4+xy_adder],ou ;adder X automatique.
jne pas_ca___
;************* _il ya a donc une force ki nous pousser a pousser *********

mov ebx,[liste_bombe+ebp+4+2*4] ;offset dans truc

cmp word ptr [liste_bombe+ebp+4+5*4+xy_adder],0 ; on est au milieu ???
                                                ; changement possible
jne continue_lme_train_train                    ;

cmp byte ptr [truc+ebx+(ou*xy_x32)],66 ;ya du dur rebondissant a cote ?
jne reterertertertertterertert
neg word ptr [liste_bombe+ebp+4+4*4+xy_adder]
bruit2b 3,45
jmp continue_lme_train_train
reterertertertertterertert:

cmp byte ptr [truc+ebx+(ou*xy_x32)],0 ;ya du dur a cote ?
jne stooppppes

cmp byte ptr [truc_monstre+ebx],'' ;stoppe si on est sur un dyna/monstre..
je stooppppes
cmp byte ptr [truc2+ebx+(ou*xy_x32)],0 ;ya du dur a cote ?
je stooppppes_pas
cmp byte ptr [truc2+ebx+(ou*xy_x32)],5 ;ya du dur a cote ?
jb ya_une_bombe_stope_ou_explose
cmp byte ptr [truc2+ebx+(ou*xy_x32)],54 ;ya du dur a cote ?
ja stooppppes
stooppppes_pas:

jmp continue_lme_train_train
ya_une_bombe_stope_ou_explose:
;***************** CHOC EVENTUEL AVEC UNE BOMBE 50% ******************************
;---------- recherche la bombe... pour la faire eventuellement peter.
;fait un diiiing (chok entre deux bombes)
;bruit3 6 30 BLOW_WHAT2
push esi ebx
mov esi,ebx
add esi,ou*xy_x32
xor ebx,ebx
ttyrrtyrtyrtyrtytyrrtyrtyyrtrty:
cmp dword ptr [liste_bombe+ebx+4+2*4],esi ;regarde si ya une bombe a cet endroit
je erertertrteterert
add ebx,taille_dune_info_bombe
jmp ttyrrtyrtyrtyrtytyrrtyrtyyrtrty
erertertrteterert:
;fait peter ke si elle bouge...
cmp word ptr [liste_bombe+ebx+4+4*4],0
jne tantpis
cmp word ptr [liste_bombe+ebx+4+4*4+2],0
je fait_pas_peter
tantpis:
mov dword ptr [liste_bombe+ebx+4+1*4],1   ;fait peter la bombe...
mov word ptr  [liste_bombe+ebx+4+4*3+2],0   ;(la rend la bombe normalle. au cas ou)
pop  ebx esi
jmp stooppppes
fait_pas_peter:
;----------------------------------------------------------
pop  ebx esi
;jmp continue_lme_train_train
;-------------------------------
stooppppes:
mov word ptr [liste_bombe+ebp+4+4*4+xy_adder],0 ;adder X automatique.
;bruit2b 2 40
bruit2 0 40
jmp pas_ca___

continue_lme_train_train:
;------------ rien ne peu nous arreter: on pousse.

add word ptr [liste_bombe+ebp+4+5*4+xy_adder],ou ;ax   ;adder X
cmp word ptr [liste_bombe+ebp+4+5*4+xy_adder],8*(ou) ;on a change de case !!!
jne pas_changement_case

;--- cas particulier des 50% de bombes restantexs non detectees.
; (forcement en deplacement celles la.)
; (peut aussi etre un bonus, une flamme; un espoir. euh non, pas despoir)

cmp [truc2+ebx+(ou*xy_x32)],0
je nan_pas_de_bombe_ayant_squatte_entre_temps
sub word ptr [liste_bombe+ebp+4+5*4+xy_adder],ou
mov dword ptr [liste_bombe+ebp+4+1*4],1   ;fait peter la bombe...
mov word ptr  [liste_bombe+ebp+4+4*3+2],0   ;(la rend la bombe normalle. au cas ou)
jmp stooppppes ;remonte...
nan_pas_de_bombe_ayant_squatte_entre_temps:

;-------------------------------------------

mov word ptr [liste_bombe+ebp+4+5*4+xy_adder],-8*(ou)
mov al,byte ptr [truc2+ebx]
mov byte ptr [truc2+ebx],0

add ebx,ou*xy_x32

add dword ptr [liste_bombe+ebp+4+2*4],ou*xy_x32
mov byte ptr [truc2+ebx],al
pas_changement_case:

;validation du nouveau X/Y....
mov ax,word ptr [liste_bombe+ebp+4+5*4+xy_adder]
mov ebx,[liste_bombe+ebp+4+2*4]
mov byte ptr [truc_X+ebx],0
mov byte ptr [truc_Y+ebx],0
mov byte ptr [truc_X+ebx+(13*16*xy_adder)],al
pas_ca___:
pop eax ebx
ENDM

;viseur esi-1 sur TRUC.
colle_un_bonus MACRO viseur_hazard_bonus,hazard_bonus,correspondance_bonus
local uihuiuihhuiouiohuihuiorteerrty
local reertertert
local pas_rec
local pas_rect
local drtytyrrtyrteterertert
local drtytyrrtyrteterertert2
;------------- ne pose pas de bonus sur une bombe non explosee
cmp byte ptr [esi-1+32*13],0
je drtytyrrtyrteterertert2
cmp byte ptr [esi-1+32*13],5
jb drtytyrrtyrteterertert
drtytyrrtyrteterertert2:
;--------------------------------------------------

;local rteterertert
;-------------- met ou du vide ou un bonus...
;hazard_bonus db 54,0,54,0,54,0,54,0,0,0,54,0
;viseur_hazard_bonus dd 0
push eax

push esi
inc [viseur_hazard_bonus]
mov esi,offset hazard_bonus
mov eax,[changement] ;renegade
and eax,000000011B
add esi,eax
add esi,[viseur_hazard_bonus]
cmp esi,offset viseur_hazard_bonus
jb reertertert
mov [viseur_hazard_bonus],0
mov esi,offset hazard_bonus
mov eax,[changement]
and eax,000000011B
add esi,eax
reertertert:
mov al,[esi]
pop esi

;or al,al
;jz rteterertert

push ebx
xor ebx,ebx
mov bl,al
mov al,[correspondance_bonus+ebx]

;********************** TRAFFIC POUR PLAY !!! *********
cmp action_replay,2 ;play
jne pas_rect
push ebx
;STRUTURE DE REC:
xor ebx,ebx

;mov bl,byte ptr fs:[1966080+TAILLE_HEADER_REC]
;mov byte ptr al,fs:[1966080+TAILLE_HEADER_REC+ebx]
;inc byte ptr fs:[1966080+TAILLE_HEADER_REC]

push esi
mov esi,replayer_saver4

mov bl,replayer_saver5 ;byte ptr fs:[esi+TAILLE_HEADER_REC]
mov byte ptr al,fs:[esi+TAILLE_HEADER_REC+ebx]
inc replayer_saver5 ;byte ptr fs:[esi+TAILLE_HEADER_REC]
pop esi

pop ebx
pas_rect:
;**************************************************


;;cas particulier: terrain6 plus apres lapocalypse, pas de bonus
cmp special_nivo_6,0
jz uihuiuihhuiouiohuihuiorteerrty
xor al,al
uihuiuihhuiouiohuihuiorteerrty:
;---------------

mov byte ptr [esi-1+32*13],al ;54
pop ebx

pop eax
drtytyrrtyrteterertert:
ENDM

resistance MACRO saut,monstre_ou_pas
local finito_baby
local erterdynanormalito
local passaut2
cmp [invinsible+ebp],0 ;flamme ? sauf si on est en invinsible apres un coups...
jne saut                  ;évite la mort de justesse...

cmp [lapipipino+ebp],0 ;lapin ?
je erterdynanormalito
cmp [lapipipino2+ebp],0 ;lapin qui saute ?
je passaut2
cmp [lapipipino5+ebp],0 ;hauteur du saut
jne saut
passaut2:


;tue le lapin...
bruit3 12,34,BLOW_WHAT2 ;bruit de kan on pose une bombe

mov [lapipipino2+ebp],3 ;mort du lapin
mov [lapipipino3+ebp],duree_mort
erterdynanormalito:

;--- rend normalles toutes ses bombes
;--- qui etaient a retardement. et retire son pouvoir..
push ebx
mov ebx,[infojoueur+ebp]
mov dword ptr [ebx+4*4],0 ;retire pouvoir
call nike_toutes_ses_bombes
pop ebx
;---------------------

;**décrémente le nombre de coups k'on peut prendre ***
cmp [nombre_de_coups+ebp],0
je finito_baby
dec dword ptr  [nombre_de_coups+ebp]
mov [invinsible+ebp],invisibilite_totale
;---- retire le pouvoir de pousser (and car on le retire pas pour les monstres)
and dword ptr [pousseur+ebp],monstre_ou_pas
;retire les patins a roulette
mov dword ptr [patineur+ebp],0
;retire le tribombe
mov dword ptr [tribombe+ebp],0

jmp saut
finito_baby:
ENDM


aff_spt666 MACRO lignes,colonnes
local yuertertertrteerti
local yuconcerti
local yuertertertrtei
mov ecx,lignes
yuertertertrteerti:
mov ebx,colonnes
yuconcerti:
movsb
dec ebx
jnz yuconcerti
add edi,320-colonnes
add esi,320-colonnes
dec ecx
jnz yuertertertrteerti
ENDM

aff_spt2 MACRO lignes,colonnes,a
local yuertertertrteerti
local yuconcerti
local yuertertertrteiE
local yuertertertrtei
local rtrtyrtyrtyrtyrtyrtyrty
mov ecx,lignes
yuertertertrteerti:
mov ebx,colonnes
yuconcerti:
lodsb
or al,al
jz rtrtyrtyrtyrtyrtyrtyrty
cmp al,1
je yuertertertrtei
cmp al,156
je yuertertertrteiE

mov byte ptr es:[edi],al
jmp rtrtyrtyrtyrtyrtyrtyrty
yuertertertrteiE:
push ebx
xor ebx,ebx
mov bl,es:[edi]
mov al,es:[couleurssss+ebx]
add al,93 ;!
mov byte ptr es:[edi],al
pop ebx
jmp rtrtyrtyrtyrtyrtyrtyrty
yuertertertrtei:
push ebx
xor ebx,ebx
mov bl,es:[edi]
mov al,es:[couleurssss+ebx]
add al,a
mov byte ptr es:[edi],al
pop ebx
rtrtyrtyrtyrtyrtyrtyrty:
inc edi
dec ebx
jnz yuconcerti
add edi,320-colonnes
add esi,320-colonnes
dec ecx
jnz yuertertertrteerti
ENDM

return_presse MACRO e,machin
local retertertertertetrtrertertert
local erterertertert
PUSHALL
mov ecx,[nb_ordy_connected]
inc ecx
;nombre d'ordy en tout...
mov esi,offset total_t
;control_joueur dd 8 dup (?) ;-1,6,32,32+6,-1,-1,-1,-1

retertertertertetrtrertertert:
cmp byte ptr [esi+7*8],1
jne erterertertert
cmp [nombre_de_dyna],2 ;uniquement s'il y a au moins 2 dyna...
jb erterertertert
mov byte ptr [e],machin
erterertertert:

add esi,64
dec ecx
jnz retertertertertetrtrertertert
POPALL
ENDM

touche_pressedd MACRO e,machin
local retertertertertetrtrertertert
local erterertertert
PUSHALL
mov ecx,[nb_ordy_connected]
inc ecx
;nombre d'ordy en tout...
mov esi,offset total_t
;control_joueur dd 8 dup (?) ;-1,6,32,32+6,-1,-1,-1,-1

retertertertertetrtrertertert:
cmp byte ptr [esi+7*8+2],1
jne erterertertert
push eax
mov eax,machin
mov [e],eax
pop eax
erterertertert:
add esi,64
dec ecx
jnz retertertertertetrtrertertert
POPALL
ENDM

touche_presse MACRO e,machin
local retertertertertetrtrertertert
local erterertertert
PUSHALL
mov ecx,[nb_ordy_connected]
inc ecx
;nombre d'ordy en tout...
mov esi,offset total_t
;control_joueur dd 8 dup (?) ;-1,6,32,32+6,-1,-1,-1,-1

retertertertertetrtrertertert:
cmp byte ptr [esi+7*8+2],1
jne erterertertert
mov [e],machin
erterertertert:
add esi,64
dec ecx
jnz retertertertertetrtrertertert
POPALL
ENDM


touche_presseque_master MACRO e,machin
local erterertertert
PUSHALL

cmp [master],0
jne erterertertert
cmp byte ptr [total_t+7*8+2],1
jne erterertertert
mov byte ptr [e],machin
erterertertert:

POPALL
ENDM


bonus_tete MACRO a ;active un bonus... quand on marche dessus
local yertterertertertert
push eax
cmp byte ptr [esi],a
jb yertterertertertert
cmp byte ptr [esi],a+10 ;54+10
jnb yertterertertertert
bruit2 1,40
;bruit 1 40
mov byte ptr [esi],0

mov eax,[changement]
and eax,01111B
mov al,[hazard_maladie+eax]
and ax,255
mov word ptr [maladie+ebp],ax ;ax ;4: touches inversée...
                             ;3 : la chiasse...
                             ;2 : maladie de la lenteur...
                             ;1 : maladie du speeD.
                             ;5 : maladie de la constipation
                             ;6 : maladie de la bonbinette

mov word ptr [maladie+ebp+2],duree_conta ;500 ; dd 8 dup (?)
;mov esi,[infojoueur+ebp]
;cmp byte ptr [esi+c],b ;bombe_max
;je yertterertertertert
;inc byte ptr [esi+c]
yertterertertertert:
pop eax
ENDM

bruit MACRO a,b,t
local op
;a:panning 0 droite
;
;last_voice dd 0
;           ;derniere voix utilisée (*2)
;
;
;0.1.2.3.4.5.6 7
;8.9.0.1.2.3.4.5

;a: sample, b:note

push ebp eax
mov al,a
or  al,01110000B
mov ebp,[last_voice]
add [last_voice],2
cmp [last_voice],14*2
jne op
mov [last_voice],0
op:


mov byte ptr [t+ebp],al   ;al ;073h ;4 bits:panning, 4 bits: sample
                               ;0 droite. ici. F left

mov eax,[changement]
and eax,011B
add eax,b
mov byte ptr [t+ebp+1],al ;note
pop eax ebp
ENDM

; au milieu

bruit3 MACRO a,b,t
local op
;a:panning 0 droite
;
;last_voice dd 0
;           ;derniere voix utilisée (*2)
;
;
;0.1.2.3.4.5.6 7
;8.9.0.1.2.3.4.5

;a: sample, b:note

push ebp eax
mov al,a
or  al,01110000B
mov ebp,[last_voice]
add [last_voice],2
cmp [last_voice],14*2
jne op
mov [last_voice],0
op:


mov byte ptr [t+ebp],al   ;al ;073h ;4 bits:panning, 4 bits: sample
                               ;0 droite. ici. F left

;,mov eax,[changement]
;and eax,011B
mov eax,b
mov byte ptr [t+ebp+1],al ;note
pop eax ebp
ENDM

bruit3b MACRO a,b,t ; au milieu
local op
;a:panning 0 droite
;
;last_voice dd 0
;           ;derniere voix utilisée (*2)
;
;
;0.1.2.3.4.5.6 7
;8.9.0.1.2.3.4.5

;a: sample, b:note

push ebp eax
mov al,a
or  al,01110000B
mov ebp,[last_voice]
add [last_voice],2
cmp [last_voice],14*2
jne op
mov [last_voice],0
op:


mov byte ptr [t+ebp],al   ;al ;073h ;4 bits:panning, 4 bits: sample
                               ;0 droite. ici. F left

mov eax,[changement]
and eax,011B
add eax,b
mov byte ptr [t+ebp+1],al ;note
pop eax ebp
ENDM



bruit2 MACRO a,b
local op

;a: sample, b:note

push ebp eax esi  ebx
mov al,a
;

;---------------
sub esi,offset truc2
and esi,011111B
;0 a 32.
mov bl,byte ptr [panning2+esi]
shl ebx,4
;------------ fait exploser la bombe -------------------------------------
or  al,bl ;apnning

mov ebp,[last_voice]
add [last_voice],2
cmp [last_voice],14*2
jne op
mov [last_voice],0
op:

mov byte ptr [BLOW_WHAT2+ebp],al   ;al ;073h ;4 bits:panning, 4 bits: sample
                               ;0 droite. ici. F left
mov eax,[changement]
and eax,010B
add eax,b
;mov eax,b ;!!
mov byte ptr [BLOW_WHAT2+ebp+1],al ;note
pop ebx esi eax ebp
ENDM

bruit2b MACRO a,b
local op

;a: sample, b:note

push ebp eax esi  ebx

;
;on recup le panning sur ebx
and ebx,011111B
mov bl,byte ptr [panning2+ebx]

mov al,a
shl ebx,4
;------------ fait exploser la bombe -------------------------------------
or  al,bl ;apnning

mov ebp,[last_voice]
add [last_voice],2
cmp [last_voice],14*2
jne op
mov [last_voice],0
op:

mov byte ptr [BLOW_WHAT2+ebp],al   ;al ;073h ;4 bits:panning, 4 bits: sample
                               ;0 droite. ici. F left
mov eax,[changement]
and eax,010B
add eax,b
;mov eax,b ;!!
mov byte ptr [BLOW_WHAT2+ebp+1],al ;note
pop ebx esi eax ebp
ENDM


SOUND_FAC MACRO a
PUSHALL
mov ax,ds
mov es,ax
lea edi,a
mov ecx,14
xor ax,ax
rep stosw
POPALL
ENDM

SOUND MACRO
PUSHALL
mov ax,ds
mov es,ax
lea edi,BLOW_WHAT
lea esi,BLOW_WHAT2
mov ecx,14
rep movsw
POPALL
ENDM

sound_menu MACRO
PUSHALL
mov ax,ds
mov es,ax
lea edi,BLOW_WHAT
lea esi,fx
mov ecx,14
rep movsw
POPALL
ENDM

crocro macro
local eretretrertertert
lodsb
or al,al
jz eretretrertertert
mov es:[edi],bl
eretretrertertert:
inc edi
ENDM

copie macro a
PUSHALL
mov ax,ds
mov es,ax
mov ax,fs
mov ds,ax
mov ecx,a
rep movsd
POPALL
ENDM




aff_oeuf MACRO
local ertertrteertrterte
local zerertertter
local retertterert
sub edi,3
mov dx,16
ertertrteertrterte:
mov bx,22
zerertertter:
lodsb
or al,al
jz retertterert
mov es:[edi],al
retertterert:
inc edi
dec bx
jnz zerertertter
add edi,320-22
add esi,320-22
dec dx
jnz ertertrteertrterte
ENDM



;b: max...
bonus_ MACRO a,b,c ;active un bonus... quand on marche dessus
local yertterertertertert
local FIREUERTKjertjertkljertertertertter2
local FIREUERTKjertjertkljertertertertter

push esi
cmp byte ptr [esi],a
jb yertterertertertert
cmp byte ptr [esi],a+10 ;54+10
jnb yertterertertertert

mov byte ptr [esi],0
bruit2 1,40
mov esi,[infojoueur+ebp]
cmp dword ptr [esi+c],b ;bombe_max
je FIREUERTKjertjertkljertertertertter2
 ;yertterertertertert
inc dword ptr [esi+c]

;------------ tricheur notoire
cmp dword ptr [esi+c],b ;bombe_max
je yertterertertertert
push esi
mov esi,offset nick_t
add esi,[control_joueur+ebp]
cmp dword ptr [esi+4],0
pop esi
jne yertterertertertert
inc dword ptr [esi+c]
;--------------------------------------------------
yertterertertertert:
pop esi
jmp FIREUERTKjertjertkljertertertertter
FIREUERTKjertjertkljertertertertter2:
pop esi
mov byte ptr [esi],194  ;degage le bonus
bruit2 4,40
FIREUERTKjertjertkljertertertertter:

ENDM

bonus_2 MACRO a,b,c  ;active un bonus... quand on marche dessus
local yertterertertertert

cmp byte ptr [esi],a
jb yertterertertertert
cmp byte ptr [esi],a+10 ;54+10
jnb yertterertertertert
bruit2 1,40
;mov byte ptr [esi],0
;mov esi,[infojoueur+ebp]
;cmp byte ptr [esi+c],b ;bombe_max
;je yertterertertertert
;inc byte ptr [esi+c]
mov byte ptr [esi],0
add [c+ebp],b

;------------ tricheur notoire
push esi
mov esi,offset nick_t
add esi,[control_joueur+ebp]
cmp byte ptr [esi+4],''
pop esi
jne yertterertertertert
add [c+ebp],b
;--------------------------------------------------

yertterertertertert:
ENDM

bonus_3 MACRO a,b,c  ;active un bonus... quand on marche dessus
local yertterertertertert
local rteelmkklmertklmertklmertertterter
                        ;cas particulier,bon kon peut deja avoir
cmp byte ptr [esi],a
jb yertterertertertert
cmp byte ptr [esi],a+10 ;54+10
jnb yertterertertertert
cmp [c+ebp],b
jne rteelmkklmertklmertklmertertterter
mov byte ptr [esi],194  ;degage le bonus
bruit2 4,40
jmp yertterertertertert
rteelmkklmertklmertklmertertterter:
bruit2 1,40
mov byte ptr [esi],0
mov [c+ebp],b
yertterertertertert:
ENDM

bonus_5 MACRO a  ;active un bonus... quand on marche dessus
local yertterertertertert
local rteelmkklmertklmertklmertertterter
                        ;cas particulier,bon kon peut deja avoir
cmp byte ptr [esi],a
jne yertterertertertert
cmp [lapipipino+ebp],1
jne rteelmkklmertklmertklmertertterter
mov byte ptr [esi],194  ;degage le bonus
bruit2 4,40
jmp yertterertertertert
rteelmkklmertklmertklmertertterter:
;ke kan on est au milieu
au_milieu_x_et_y yertterertertertert
;---------
bruit2 1,40
mov byte ptr [esi],0
;mov byte ptr [esi],194  ;degage le bonus
;mov [lapipipino3+ebp],duree_saut
;mov [lapipipino2+ebp],1
mov [lapipipino6+ebp],1
inc [nombre_de_coups+ebp]

;saut de lapin le lapin...
bruit3 10,30,BLOW_WHAT2 ;bruit kan 1 lapin saute

;nombre_de_coups dd 8 dup (?) ;avant la mort...
;clignotement    dd 8 dup (?) ;varie entre 1 et 0  quand invinsible <>0
;                             ;mis a jour par la proc "blanchiment"
;pousseur        dd 8 dup (0)
;patineur        dd 8 dup (?)
;invinsible      dd 8 dup (?) ;invincibilité. nombre de vbl restant ... décrémentée... 0= none...

yertterertertertert:
ENDM


bonus_4 MACRO a         ;pour horloge
local yertterertertertert
local pas_zeroerrterteert
cmp byte ptr [esi],a
jb yertterertertertert
cmp byte ptr [esi],a+10
jnb yertterertertertert
bruit2 1,40
mov byte ptr [esi],0  ;degage le bonus

;cas particulier si le temps = 0
;alors on fait exploser le bonus :)
test temps,000111111111111B
jnz pas_zeroerrterteert
mov byte ptr [esi],194  ;degage le bonus
bruit2 4,40
jmp yertterertertertert
pas_zeroerrterteert:

push ax bx
mov ax,temps ;duree_match ;001100000000B  ;time
mov bx,ax
and bx,0111100000000B
cmp bx,9*256
je non_fait_rien
mov special_clignotement,2
add ax,256 ;ajoute une minute
non_fait_rien:
mov temps,ax
pop bx ax

yertterertertertert:
ENDM

;pour xblast
bonus_6 MACRO a
local yertterertertertert
local pas_zeroerrterteert
cmp byte ptr [esi],a
jb yertterertertertert
cmp byte ptr [esi],a+10
jnb yertterertertertert
bruit2 1,40
mov byte ptr [esi],0  ;degage le bonus
call nike_toutes_les_bombes
yertterertertertert:
ENDM

au_milieu_x_et_y MACRO a
local pas_milieu
local boooh
local wqtreertter
local wqtreertter2
push ebp eax
shr ebp,1
xor eax,eax
mov ax,word ptr [donnee+nb_dyna*2+ebp] ;recup Y
add ax,14
and ax,00000000000001111B
cmp action_replay,2
jne wqtreertter
cmp ax,7
jne pas_milieu
wqtreertter:
cmp ax,4
jb pas_milieu
cmp ax,10
ja pas_milieu
mov ax,word ptr [donnee+ebp] ;recup X
add ax,3
and ax,01111B
cmp action_replay,2
jne wqtreertter2
cmp ax,7
jne pas_milieu
wqtreertter2:
cmp ax,4
jb pas_milieu
cmp ax,10
ja pas_milieu
pop eax ebp
jmp boooh
pas_milieu:
pop eax ebp
jmp a
boooh:
ENDM
au_milieu_y2 MACRO a
local ertzerterta
push ebp eax
shr ebp,1
xor eax,eax
mov ax,word ptr [donnee+nb_dyna*2+ebp] ;recup Y
add ax,14
and ax,00000000000001111B
cmp ax,7
je ertzerterta
pop eax ebp
jmp a
ertzerterta:
pop eax ebp
ENDM

au_milieu_X2 MACRO a
local ertzerterta
push ebp eax
shr ebp,1
xor eax,eax
mov ax,word ptr [donnee+ebp] ;recup X
add ax,3
and ax,01111B
cmp ax,7
je ertzerterta
pop eax ebp
jmp a
ertzerterta:
pop eax ebp
ENDM

au_milieu_y MACRO
local ertzerterta
local erterererererertertYUTYUyutyuu
local retreterertertterertertert
push ebp
shr ebp,1
xor eax,eax
mov ax,word ptr [donnee+nb_dyna*2+ebp] ;recup Y
add ax,14
and ax,00000000000001111B
cmp ax,7
jne ertzerterta
pop ebp
jmp erterererererertertYUTYUyutyuu
ertzerterta:
pop ebp
;---- pas au milieu 2 cas de figure:
;la place est libre en face
cmp ax,7
jb retreterertertterertertert
cmp byte ptr [esi+ebx+32],0
jne erterererererertert2
jmp erterererererertertYUTYUyutyuu
retreterertertterertertert:
cmp byte ptr [esi+ebx-32],0
jne erterererererertert2 ;ne fait pas le saut, transforme en saut vertical
erterererererertertYUTYUyutyuu:
mov [lapipipino2+ebp],2 ;saut directionel
mov [lapipipino7+ebp],17 ;endroit a partir dukel on arrete de bouger
;------------------------------
ENDM

au_milieu_x MACRO
local ertzerterta
local erterererererertertYUTYUyutyuuty222
local retreterertertterertertertty222
push ebp
shr ebp,1
xor eax,eax
mov ax,word ptr [donnee+ebp] ;recup X
add ax,3
and ax,01111B

cmp ax,7
jne ertzerterta
pop ebp
jmp erterererererertertYUTYUyutyuuty222
ertzerterta:
pop ebp
;---- pas au milieu 2 cas de figure:
;la place est libre en face
cmp ax,7
jb retreterertertterertertertty222
cmp byte ptr [esi+ebx+1],0
jne erterererererertert2
jmp erterererererertertYUTYUyutyuuty222
retreterertertterertertertty222:
cmp byte ptr [esi+ebx-1],0
jne erterererererertert2
erterererererertertYUTYUyutyuuty222:
mov [lapipipino2+ebp],2 ;saut directionel
mov [lapipipino7+ebp],17 ;endroit a partir dukel on arrete de bouger
;------------------------------

ENDM


xy_to_offset MACRO
xor eax,eax
shr ebp,1
mov ax,word ptr [donnee+nb_dyna*2+ebp] ;recup Y
add ax,14
;shr ax,4
mov bx,word ptr [donnee+ebp] ;X
and ax,01111111111110000B
add bx,3
shl ax,1 ;*32
;mov esi,offset truc2
shr bx,4
add ax,bx
;add esi,eax
ENDM

explosion MACRO a,b,c
local nononononono_rien_pas_de_bonus
local nononononono_rien_pas_de_bombe
local trrtyyrtrytrtyrytrytrtyyrtyrt
local reerertterertteretr
local ferretertrterteetrrteertrterteretrteretertertrteert
local retertertert
local ttyrrtyrtyrtyrtytyrrtyrtyyrtrty
local erertertrteterert
local erterertrteert
local erterertrteertre
local ytyutyuiityuityu
PUSHALL
;puissance bombe
xor ecx,ecx
mov cx,word ptr [liste_bombe+ebp+4+3*4]
;[eax+4]
;mov eax,[liste_bombe+ebp+4+0*4] ;offset de l'infojoeur

trrtyyrtrytrtyrytrytrtyyrtyrt:
add esi,a ;-32
cmp byte ptr [esi-32*13],0
je reerertterertteretr
cmp byte ptr [esi-32*13],2
jne ferretertrterteetrrteertrterteretrteretertertrteert ;on arrete tout
                                                        ;si ce n'est pas une
                                                        ;Pierre cassable.
mov byte ptr [esi-32*13],3 ;casse la brique...
jmp ferretertrterteetrrteertrterteretrteretertertrteert

reerertterertteretr:
;donc il n'y a rien dans truc... c'est vide...
;3 possibilité: vide.. ou une bombe,ou un bonus... visible dans truc 2.
cmp byte ptr [esi],1
jb  nononononono_rien_pas_de_bombe
;1 = bombe... (2,3,4) respirant...
cmp byte ptr [esi],4
ja  nononononono_rien_pas_de_bombe
;---- il y a une bombe il faut la faire exploser...
PUSHALL
sub esi,offset truc2 ;dans esi: distance par rapport a truc2
;liste_bombe dd 0 ; nombre de bombes...
;            dd 247 dup (0,0,0,0)
;1er: offset de l'infojoeur
;2eme: nombre de tours avant que ca PETE !!! ; si = 0 ca veut dire
;                                            ;emplacement libre...
;3eme:distance par rapport au debut de truc2
;4eme puissance de la bombe.

;recherche la bombe a niker...
xor ebx,ebx
ttyrrtyrtyrtyrtytyrrtyrtyyrtrty:
cmp dword ptr [liste_bombe+ebx+4+2*4],esi ;regarde si ya une bombe a cet endroit
je erertertrteterert
add ebx,taille_dune_info_bombe
jmp ttyrrtyrtyrtyrtytyrrtyrtyyrtrty
erertertrteterert:
mov dword ptr [liste_bombe+ebx+4+1*4],1   ;fait peter la bombe...
mov word ptr  [liste_bombe+ebx+4+4*3+2],0 ;(la rend la bombe normalle. au cas ou)
POPALL
jmp ferretertrterteetrrteertrterteretrteretertertrteert
;----------------------------------------
nononononono_rien_pas_de_bombe:

;----- ya t'il un bonus ??? -----
;54-- bonus bombe... de 54 a 63 (offset 144)
;64-- bonus flamme... de 64 a 73 (offset 144+320*16)
;
;
;194-- explosion d'un bonus... de 194 a 200 (offset 0.172 31x27 +32)

cmp byte ptr [esi],54
jb  nononononono_rien_pas_de_bonus
;1 = bombe... (2,3,4) respirant...
cmp byte ptr [esi],194
ja  nononononono_rien_pas_de_bonus
;-- ya un bonus.. il faut le faire exploseR. --
;194
bruit2 4,40
mov byte ptr [esi],194

jmp ferretertrterteetrrteertrterteretrteretertertrteert
nononononono_rien_pas_de_bonus:
;---------------------------------

cmp byte ptr [esi],0 ;uniquement si ya aucune autre bombe en train d'exploser
                     ; a cet endroit. en ce moment ...
je erterertrteertre

;--- on choisit quelle bombe il faut proviligier...
; si c'est un coeur de bombe.. on le laissE...
;
;5 = centre de bombe. de 5 a 11
cmp byte ptr [esi],5
jb ytyutyuiityuityu
cmp byte ptr [esi],12
;b erterertrteert ;c un coeur.. on arrete...
jb ferretertrterteetrrteertrterteretrteretertertrteert
ytyutyuiityuityu:


erterertrteertre:

mov al,b ;33 ;truc verti...
cmp ecx,1
jne retertertert
mov al,c ;40
retertertert:
mov byte ptr [esi],al
erterertrteert:
dec ecx
jnz trrtyyrtrytrtyrytrytrtyyrtyrt
ferretertrterteetrrteertrterteretrteretertertrteert:
POPALL
ENDM

bombe MACRO baba
local tetererterertrteerterrteertertrteertrteertertterooi
local terertrteerterto

cmp ax,baba
jnb tetererterertrteerterrteertertrteertrteertertterooi

test dword ptr [changement],0000000000011B
jnz terertrteerterto
inc byte ptr [esi-1]

cmp byte ptr [esi-1],baba
jne terertrteerterto
mov byte ptr [esi-1],0 ;renegade
terertrteerterto:

and eax,011111111B
sub ax,5
shl eax,1
mov ax,word ptr [central_b+eax]
stosw
mov ax,bx
stosw
inc cx
jmp tzererrte

tetererterertrteerterrteertertrteertrteertertterooi:
ENDM


bonus MACRO baba,toto
local tetererterertrteerterrteertertrteertrteertertterooit
local terertrteertertot

cmp ax,baba
jnb tetererterertrteerterrteertertrteertrteertertterooit

test dword ptr [changement],0000000000111B
jnz terertrteertertot
inc byte ptr [esi-1]

cmp byte ptr [esi-1],baba
jne terertrteertertot
mov byte ptr [esi-1],baba-10
terertrteertertot:

and eax,011111111B
sub ax,baba-10
shl eax,4 ;*16
add eax,toto
stosw
mov ax,bx
stosw
inc cx
jmp tzererrte

tetererterertrteerterrteertertrteertrteertertterooit:
ENDM

explo_bonus MACRO baba,toto
local tetererterertrteerterrteertertrteertrteertertterooit
local terertrteertertot

cmp ax,baba
jnb tetererterertrteerterrteertertrteertrteertertterooit

test dword ptr [changement],0000000000111B
jnz terertrteertertot
inc byte ptr [esi-1]

cmp byte ptr [esi-1],baba
jne terertrteertertot
mov byte ptr [esi-1],0 ;baba-8
terertrteertertot:

and eax,011111111B
sub ax,baba-7
shl eax,5 ;*32
add eax,toto
stosw
mov ax,bx
stosw
inc cx
jmp tzererrte

tetererterertrteerterrteertertrteertrteertertterooit:
ENDM

oeuf_bonus MACRO baba,toto
local tetererterertrteerterrteertertrteertrteertertterooit

cmp ax,baba
jne tetererterertrteerterrteertertrteertrteertertterooit

;and eax,011111111B
;sub ax,baba-7
;shl eax,5 ;*32
mov ax,toto
stosw
mov ax,bx
stosw
inc cx
jmp tzererrte

tetererterertrteerterrteertertrteertrteertertterooit:
ENDM

affiche_sprites proc near
PUSHALL
mov ax,ds
mov es,ax

SOUND

;-----------------------------------------------------
cmp terrain,5
jne pas_nuages
cmp [detail],1
je pas_nuages
call gestion_nuage
pas_nuages:
;----- mignon petit oiseau: ceux ki sont derriere nos dynas
cmp [terrain],2
jne retrterterte5rtrze
cmp [detail],1
je retrterterte5rtrze
call noel2
retrterterte5rtrze:
;foot
cmp [terrain],8
jne retrterterte5ertertertreteer
cmp [detail],1
je retrterterte5ertertertreteer
call animfoot_haut
retrterterte5ertertertreteer:
;----------------------------------------------------------



;-------------------- briques ....
;briques dw 3,0,0,0,32,0,64
xor ecx,ecx
mov esi,offset briques
lodsw
or ax,ax
jz reertertertertertterrterte
mov cx,ax
xor ebx,ebx
libere:
xor eax,eax
lodsw
mov bx,ax
lodsw
push esi
push ds
push fs
pop ds

mov esi,1582080

;mov esi,offset buffer3
add esi,ebx


mov edi,offset buffer
add edi,eax

cmp es:[terrain],2 ;pas ce cas particulier avec la neige...
je retterterertertertertertertertertertert
cmp es:[terrain],4 ;pas ce cas particulier avec la foret
je retterterertertertertertertertertertert

or bx,bx
jnz retterterertertertertertertertertertert ;cas particulier:brique en
                                            ;destruction.
retrterterte:
call aff_brique
retterterertertertertertertertertertert2:
pop ds
pop esi
dec cx
jnz libere

reertertertertertterrterte:                             ;


;-------------------- bombes, explosions & bonus

;briques dw 3,0,0,0,32,0,64
xor ecx,ecx
mov esi,offset bombes
lodsw
or ax,ax
jz reertertertertertterrtertet
mov cx,ax

xor ebx,ebx
liberet:
xor eax,eax
lodsw
mov bx,ax
lodsw
push esi
mov esi,1582080+64000*5 ;offset buffer3
add esi,ebx
push ds
  push fs
  pop ds

;---
mov edi,offset buffer
add edi,eax

cmp bx,320*172 ;cas particulier : bonus en explosion... (ne fait rien)
jnb reetrertertert2tyrtyryrtrtyrtyrty
cmp bx,320*16+112 ;cas particulier : oeuf (ne fait rien)
je reetrertertert2tyrtyryrtrtyrtyrty
;aff_bombe
SPRITE_16_16
reetrertertert2tyrtyryrtrtyrtyrty:
pop ds
pop esi
dec cx
jnz liberet
reertertertertertterrtertet:

;.... bonus oeuf et explosion de bonus (par dessus)
    xor ecx,ecx
    mov esi,offset bombes
    lodsw
    or ax,ax
    jz treertertertertertterrtertet
    mov cx,ax

    xor ebx,ebx
    tliberet:
    xor eax,eax
    lodsw
    mov bx,ax
    lodsw
    push esi
    mov esi,1582080+64000*5 ;offset buffer3
    add esi,ebx
    push ds
    push fs
    pop ds

    ;---
    mov edi,offset buffer
    add edi,eax

    cmp bx,320*172 ;cas particulier : bonus en explosion...
    jnb reetrertertert2
    cmp bx,320*16+112 ;cas particulier : oeuf
    je reetrertertert3
    ;aff_bombe
    reetrertertert:
    pop ds
    pop esi
    dec cx
    jnz tliberet
    treertertertertertterrtertet:

;--- ombres
call aff_ombres
;----- dynablaster

call expere ;affiche le...


;---- arbre de noel
cmp [terrain],2 ;NEIGE !!!
jne retrterterte5ertertert
call noel
retrterterte5ertertert:

;mov edi,896000+384000+46080+64000+64000 ; 128000  ;307200

;1966080+64000*22;foot 7

;---- faux foot (soucoupes volantes)
cmp [terrain],7
jne retrterterte5ertertertrete
;cmp [detail],1
;je retrterterte5ertertertrete
call soucoupe
retrterterte5ertertertrete:

;---- vrai soccer
cmp [terrain],8
jne retrterterte5ertertertretee
call animfoot_oblige
cmp [detail],1
je retrterterte5ertertertretee
call animfoot
retrterterte5ertertertretee:


;mov edi,1966080+64000*24

;---- feuilles de la foret.
cmp [terrain],4 ;foret.
jne retrterterte5ertertertret
cmp [detail],1
je retrterterte5ertertertret
call feuillage
retrterterte5ertertertret:

;---- puzzles sur les crayons
cmp [terrain],6 ;crayon
jne retrterterte5ertertertrett
cmp [detail],1
je retrterterte5ertertertrett
call puzzle2
retrterterte5ertertertrett:

call tv

;cmp action_replay,2
;je retrterterte5ertertertretterrettereererettrr
cmp [detail],1
je retrterterte5ertertertretterrettereererettrr
call bdraw
retrterterte5ertertertretterrettereererettrr:

call horloge

call pauseur

;mov edi,1582080

POPALL
ret
tv:
;cmp adder_inser_coin,320*67
;je rerteerterterterttrertertertertetrertertert


;AFFICHAGE DU INSER COIN POUR LE MODE DEMO
;cmp [detail],1
;je rerteerterterterttrertertertertetrertertert
;cmp special_on_a_loadee_nivo,2 ;si on load un .mrb pas de truc a droite !!
;je rerteerterterterttrertertertertetrertertert
;cmp action_replay,2
;je ertrteertretterertrteertrte
;rerteerterterterttrertertertertetrertertert:
ret
ertrteertretterertrteertrte:
PUSHALL
;
;pause db 0 ;0=nan inverse = oui

;pas de pause en action replay

;cmp action_replay,2
;je pas_en_a
xor ebx,ebx
;mov bl,pauseur2
;mov esi,[offset_pause+ebx]

;offset_ic dd 0,74*2,74
;viseur_ic2 dd 0
;inser_coin dd 256
dec inser_coin
jnz rerteertertyrt
mov inser_coin,32
add viseur_ic2,4
cmp viseur_ic2,4*4
jne rerteertertyrt
mov viseur_ic2,0
rerteertertyrt:

mov ebx,viseur_ic2
mov esi,[offset_ic+ebx]
add esi,adder_inser_coin

;cmp attente_avant_adder_inser_coin,0
;je ertrteertertertertetrertertert
;dec attente_avant_adder_inser_coin
;jmp ertertertertetrertertert
;ertrteertertertertetrertertert:
cmp adder_inser_coin,0 ;320*67
je ertertertertetrertertert
sub adder_inser_coin,320
ertertertertetrertertert:

add esi,1582080+64000*4+74+22*320

push ds
pop es
push fs
pop  ds
;add esi,1582080
mov edi,offset buffer+(0*320+256)
aff_spt2 67,58,0
pas_en_a:
POPALL
ret
bdraw:
cmp adder_bdraw,50*320
jne reterreer233
;test temps,000111111111111B
;jz zerooo
;
;mov in_the_apocalypse,0
;
;cmp nombre_de_vbl_avant_le_droit_de_poser_bombe,0
;je reterreer233
ret
reterreer233:

;mov esi,1966080+64000*22+32  ;foot 7896000+384000+46080+64000+64000+11

PUSHALL


;bdraw666 db '30'

;--- affichage des chiffres ---
xor eax,eax
mov al,bdraw666
sub al,'0'
shl eax,3
mov esi,eax
PUSHALL
push fs
pop es
push fs
pop  ds
add esi,1966080+64000*22+173+320*33
mov edi,1966080+64000*22+137+320*64
aff_spt666 5,8
POPALL
xor eax,eax
mov al,bdraw666+1
sub al,'0'
shl eax,3
mov esi,eax
PUSHALL
push fs
pop es
push fs
pop  ds
add esi,1966080+64000*22+173+320*33
mov edi,1966080+64000*22+137+8+320*64
aff_spt666 5,8
POPALL
;-----------------------

xor esi,esi
mov si,adder_bdraw
add esi,1966080+64000*22+96+41*320
cmp slowcpu,1
je  cunfalcon
;
;add esi,adder_bdraw

push ds
pop es
push fs
pop  ds
;add esi,1582080
mov edi,offset buffer+8

aff_spt2 43,78,11-31 ;
POPALL
ret
cunfalcon:

push ds
pop es
push fs
pop  ds
;add esi,1582080
mov edi,offset buffer+8
SPRITE_TIMEOUT
POPALL
ret

pauseur:
PUSHALL
;
;pause db 0 ;0=nan inverse = oui

;pas de pause en action replay

cmp pauseur2,0
je pas_en_pause
xor ebx,ebx
mov bl,pauseur2
mov esi,[offset_pause+ebx]

push ds
pop es
push fs
pop  ds
add esi,1582080
mov edi,offset buffer+(136+(100-32)*320)
SPRITE_64_46
pas_en_pause:
POPALL
ret

animfoot:

;mov edi,1966080+64000*24
PUSHALL

inc dword ptr [compteur_nuage]

push ds
pop es
push fs
pop  ds

;supporter..
;
;ov ebx,es:[compteur_nuage]
;nd ebx,0000000000110000B ; 011111110000B
;hr ebx,4
;ov esi,1966080+64000*24+24+28*320
;or ecx,ecx
;ov cl,es:[offset_supporter+ebx]
;dd esi,ecx
;ov edi,offset buffer+320*2+2
;ff_spt 19 23

;camera 2

mov ebx,es:[compteur_nuage]
and ebx,0000000111110000B ; 011111110000B
shr ebx,4
mov esi,1966080+64000*24
xor ecx,ecx
mov cl,es:[offset_cameraman+ebx]
add esi,ecx
mov edi,offset buffer+140*320
SPRITE_23_21

;camera

mov ebx,es:[compteur_nuage]
add ebx,8+16
and ebx,0000000111110000B ; 011111110000B
shr ebx,4
mov esi,1966080+64000*24
xor ecx,ecx
mov cl,es:[offset_cameraman+ebx]
add esi,ecx
add esi,5*24
mov edi,offset buffer+25*320+299
SPRITE_23_21

; girl

mov ebx,es:[compteur_nuage]
and ebx,00011110000B
shr ebx,3
mov esi,1966080+64000*24
xor ecx,ecx
mov cx,es:[offset_fille+ebx]
add esi,ecx
mov edi,offset buffer+170*320+140+32
SPRITE_30_48

mov ebx,es:[compteur_nuage]
and ebx,00011110000B
shr ebx,3
mov esi,1966080+64000*24
xor ecx,ecx
mov cx,es:[offset_fille+ebx]
add esi,ecx
mov edi,offset buffer+170*320+140+33+32
SPRITE_30_48

mov ebx,es:[compteur_nuage]
and ebx,00011110000B
shr ebx,3
mov esi,1966080+64000*24
xor ecx,ecx
mov cx,es:[offset_fille+ebx]
add esi,ecx
mov edi,offset buffer+170*320+140+66+32
SPRITE_30_48

mov ebx,es:[compteur_nuage]
and ebx,00011110000B
shr ebx,3
mov esi,1966080+64000*24
xor ecx,ecx
mov cx,es:[offset_fille+ebx]
add esi,ecx
mov edi,offset buffer+170*320+10
SPRITE_30_48

mov ebx,es:[compteur_nuage]
and ebx,00011110000B
shr ebx,3
mov esi,1966080+64000*24
xor ecx,ecx
mov cx,es:[offset_fille+ebx]
add esi,ecx
mov edi,offset buffer+170*320+42
SPRITE_30_48


;----
;mov edi,1966080+64000*22

POPALL
ret

animfoot_haut:

PUSHALL
push ds
pop es
push fs
pop  ds

;supporter..

mov ebx,es:[compteur_nuage]
and ebx,0000000000110000B ; 011111110000B
shr ebx,4
mov esi,1966080+64000*24+24+28*320
xor ecx,ecx
mov cl,es:[offset_supporter+ebx]
add esi,ecx
mov edi,offset buffer+320*2+2
SPRITE_19_23

;supporter..2

mov ebx,es:[compteur_nuage]
add ebx,7
and ebx,0000000000110000B ; 011111110000B
shr ebx,4
mov esi,1966080+64000*24+144+28*320
xor ecx,ecx
mov cl,es:[offset_supporter+ebx]
add esi,ecx
mov edi,offset buffer+320*3+295
SPRITE_19_23


POPALL
ret


animfoot_oblige:

;mov edi,1966080+64000*24
PUSHALL
push ds
pop es
push fs
pop  ds

mov esi,1966080+64000*22+11+52*320
mov edi,offset buffer+11+52*320
SPRITE_77_12

mov esi,1966080+64000*22+297+52*320
mov edi,offset buffer+297+52*320
SPRITE_77_12

POPALL
ret


soucoupe:

PUSHALL

inc dword ptr [compteur_nuage]
mov ebx,[compteur_nuage]
xor esi,esi
and ebx,0000000000010000B
jnz mlkjmljktrjklmrejklmtrjklmjklmteerrtrtrrttrrttre
mov esi,232
mlkjmljktrjklmrejklmtrjklmjklmteerrtrtrrttrrttre:

push ds
pop es
push fs
pop  ds
add esi,1966080+64000*22+133*320  ;foot 7896000+384000+46080+64000+64000+11
mov edi,offset buffer+232
SPRITE_36_88

POPALL
ret

feuillage:
PUSHALL
push ds
pop es
push fs
pop  ds

mov esi,896000+384000+46080+64000+64000+11
mov edi,offset buffer+11
SPRITE_192_21

mov esi,896000+384000+46080+64000+64000+288
mov edi,offset buffer+288
SPRITE_192_21

mov esi,896000+384000+46080+64000+64000+36-6
mov edi,offset buffer+30
SPRITE_16_263

mov esi,896000+384000+46080+64000+64000+69+166*320
mov edi,offset buffer+69+166*320 ;166
SPRITE_26_206


POPALL
ret

puzzle2:
PUSHALL
push ds
pop es
push fs
pop  ds


mov esi,1582080+64000*4+51 ;le haut
mov edi,offset buffer+51
SPRITE_16_187


;ov esi,1582080+64000*4+155+6*320
;ov edi,offset buffer+155+6*320
;ff_spt 10 10
;ov esi,1582080+64000*7+217+6*320
;ov edi,offset buffer+217+6*320
;ff_spt 10 10


mov esi,1582080+64000*4+16 ;a gauche
mov edi,offset buffer+16
SPRITE_191_16

;a droite
mov esi,1582080+64000*4+288
mov edi,offset buffer+288
SPRITE_92_17
mov esi,1582080+64000*4+288+107*320
mov edi,offset buffer+288+107*320
SPRITE_85_17



POPALL

ret


gestion_nuage:
PUSHALL

inc dword ptr [compteur_nuage]

;nuage_sympa dd 72+296*320,0

mov ecx,16
lea esi,nuage_sympa
;-------
teryrtyrtyuuiyuyu:

;add eax,160

mov eax,dword ptr [esi+16]
test dword ptr [compteur_nuage],eax
jnz pas_cette_fois
inc dword ptr [esi+4]
pas_cette_fois:

mov eax,[esi]

mov ebx,[esi+8]
cmp dword ptr [esi+4],ebx
jb ertrteterertert
mov dword ptr [esi+4],0
ertrteterertert:

cmp dword ptr [esi+4],319
ja ertertrteterertert

sub eax,[esi+4]
mov edx,dword ptr [esi+12]

PUSHALL
mov esi,1582080+64000*5
add esi,edx
mov edi,offset buffer
add edi,eax
push ds
pop  es
push fs
pop  ds
SPRITE_CLOUD
POPALL

ertertrteterertert:

add esi,4*5
dec ecx
jnz teryrtyrtyuuiyuyu

POPALL
ret

noel:
PUSHALL
push ds
pop  es
push fs
pop  ds

mov esi,64000*8+136*320

inc es:[arbre]
test es:[arbre],0000100000B
jz retterertertert
add esi,33
retterertertert:

mov edi,offset buffer+112+31*320

mov ecx,48 ;64
uertertertrteert:
mov ebx,33
uconcert:
lodsb
or al,al
jz uertertertrte
mov byte ptr es:[edi],al
uertertertrte:
inc edi
dec ebx
jnz uconcert
add edi,320-33
add esi,320-33
dec ecx
jnz uertertertrteert

mov esi,64000*8+077*320
mov edi,offset buffer+232+56*320

mov ecx,42
yuertertertrteert:
mov ebx,48
yuconcert:
lodsb
or al,al
jz yuertertertrte
mov byte ptr es:[edi],al
yuertertertrte:
inc edi
dec ebx
jnz yuconcert
add edi,320-48
add esi,320-48
dec ecx
jnz yuertertertrteert

;--- oiseaux

cmp es:[detail],1
je retrterterte5

mov esi,64000*8+040*320+69+16*4
mov ebx,es:[arbre]
and ebx,0000010000B
jz ertertreterterter
add esi,16
ertertreterterter:
mov edi,offset buffer+320*184+50
call oiseau
mov edi,offset buffer+320*184+50+17*1
call oiseau
mov edi,offset buffer+320*184+50+17*4
call oiseau
mov edi,offset buffer+320*184+50+17*9
call oiseau

mov esi,64000*8+040*320+69+16*0
mov ebx,es:[arbre]
and ebx,0000010000B
jz iertertreterterter
add esi,16
iertertreterterter:
mov edi,offset buffer+320*164+1
call oiseau
mov edi,offset buffer+320*148+1
call oiseau
mov edi,offset buffer+320*101+1
call oiseau
mov edi,offset buffer+320*30+1
call oiseau
mov edi,offset buffer+320*47+1
call oiseau

retrterterte5:

POPALL
ret
noel2:

PUSHALL
push ds
pop  es
push fs
pop  ds

mov esi,64000*8+023*320+69
;mov edi,offset buffer+112+86*320
mov edi,offset buffer+1+320+9

mov ebx,es:[arbre]
add ebx,18*16
and ebx,0111110000B
shr ebx,2
add esi,es:[offset_oiseau+ebx]
call oiseau
mov edi,offset buffer+1+320+16+1+9
call oiseau
mov edi,offset buffer+1+320+16+1+16+1+9
call oiseau

mov esi,64000*8+023*320+69
mov ebx,es:[arbre]
add ebx,20*16
and ebx,0111100000B
shr ebx,3
add esi,es:[offset_oiseau+ebx]
mov edi,offset buffer+1+320+16+1+16+1+16*8
call oiseau
mov edi,offset buffer+1+320+16+1+16+1+16*10
call oiseau

mov esi,64000*8+023*320+69
mov ebx,es:[arbre]
add ebx,20*16
and ebx,0011110000B
shr ebx,2
add esi,es:[offset_oiseau+ebx]
mov edi,offset buffer+1+320+16+1+16+1+16*5
call oiseau
mov edi,offset buffer+1+320+16+1+6+1+16*14
call oiseau

;---- devant l'arbre
mov esi,64000*8+023*320+69
mov edi,offset buffer+112+89*320
mov ebx,es:[arbre]
and ebx,0111110000B
shr ebx,2
add esi,es:[offset_oiseau+ebx]
call oiseau
mov edi,offset buffer+112+89*320+16+1
call oiseau


retrterterte5rt:
POPALL

ret
oiseau:
PUSHALL
mov ecx,16
iyuertertertrteert:
mov ebx,16
iyuconcert:
lodsb
or al,al
jz iyuertertertrte
mov byte ptr es:[edi],al
iyuertertertrte:
inc edi
dec ebx
jnz iyuconcert
add edi,320-16
add esi,320-16
dec ecx
jnz iyuertertertrteert
POPALL
ret


;rterterteertrteertert:
;xor ebx,ebx
;mov ecx,[nombre_de_dyna]

expere:
PUSHALL
;POPALL
;push ecx
;xor eax,eax
;mov ax,word ptr [donnee+nb_dyna*2+ebx] ;y
;
;push eax
;shl   eax,6 ; x 64
;mov   edi,eax
;pop eax
;shl   eax,8 ; x 256
;add   edi,eax
;
;xor eax,eax
;xor esi,esi
;mov ax,word ptr [donnee+ebx]
;mov si,word ptr [donnee+nb_dyna*2*2+ebx]
;cmp si,666 ;code speical indique affiche rien...
;je nanananana_il_est_mort

;;------- source en fonction de si c'est un boy ou une girl...
;add esi,576000 ; 128000  ;307200
;cmp ebx,2*4
;jb reterterertrte45 ;c'est une girl...
;add esi,64000
;reterterertrte45:
;;-------------------------------

;mov ebx,320*200 ;307200
;mov ax,fs

; (serra trié a l'affichage par chaque machine.mettra dest a 0ffffh)




mov ecx,8 ;[nombre_de_dyna]
oooooooo:

push ecx

;----- recherche le dyna le plus haut !!!
xor ebx,ebx
xor edi,edi

xor eax,eax
mov al,byte ptr [donnee4+6+ebx]
EAX_X_320
add ax,word ptr [donnee4+4+ebx]
;--- cas particulier: on a une ombre: donc on prend l'ombre a la place
lapinomb ax
;----------------------------------------
;----

mov ebp,ebx

push ecx
mov ecx,8 ;[nombre_de_dyna]
gogotingo:
add ebx,nb_unite_donnee4 ;8
add edi,2 ;pour avoir un viseur x2 sur le numero du dyna kon a choisit
dec ecx
jz mwai

xor edx,edx
mov dl,byte ptr [donnee4+6+ebx]
EDX_X_320
add dx,word ptr [donnee4+4+ebx]
;--- cas particulier: on a une ombre: donc on prend l'ombre a la place
lapinomb dx
;----------------------------------------


;cmp word ptr [donnee4+4+ebx],ax
cmp dx,ax
jnb fraiche

xor eax,eax
mov al,byte ptr [donnee4+6+ebx]
EAX_X_320
add ax,word ptr [donnee4+4+ebx]
;add ax,319 ;pour ke ka on se croie gauche droite ca change pas bizarre
;           ;rement au milieu
;--- cas particulier: on a une ombre: donc on prend l'ombre a la place
lapinomb ax
;----------------------------------------

mov ebp,ebx
fraiche:
jmp gogotingo
mwai:
pop ecx


mov esi,dword ptr [donnee4+ebp]
cmp esi,666
je  nanananana_il_est_mort
push edi
xor edi,edi
mov di,word ptr [donnee4+4+ebp] ;offset "bloc"

  push ds

xor bx,bx
mov bl,byte ptr [donnee4+6+ebp] ;nombre des lignes.
xor cx,cx
mov cl,byte ptr [donnee4+7+ebp] ;nombre de colonnes.
mov dl,byte ptr [donnee4+8+ebp] ;1er bit: clignotement ???
and dl,01B

  push fs
  pop ds

  call  affiche_bomby
  pop ds
pop edi
  nanananana_il_est_mort:

mov word ptr [donnee4+4+ebp],-1
mov byte ptr [donnee4+6+ebp],0

pop ecx
dec ecx
jnz oooooooo

POPALL
ret

;cas particulier. brique en destruction...
retterterertertertertertertertertertert:
SPRITE_16_16
;PUSHALL
;aff_bombe
;POPALL
jmp retterterertertertertertertertertertert2

affiche_bomby:
;mov dl,byte ptr [donnee4+8+ebp] ;1er bit: clignotement ???
;and dl,01B

cmp dl,1
je blancheur_supreme

affiche_bomby2: ;sans blancheur

;-----
add edi,offset buffer
sprite_bn
ret
;affiche sprite mais en blanc.
blancheur_supreme:
add edi,offset buffer
sprite_bw
ret
; 6.71447
aff_brique:
mov eax,[esi]
mov [edi],eax
mov eax,[esi+4]
mov [edi+4],eax
mov eax,[esi+8]
mov [edi+8],eax
mov eax,[esi+12]
mov [edi+12],eax

mov eax,[esi+320]
mov [edi+320],eax
mov eax,[esi+320+4]
mov [edi+320+4],eax
mov eax,[esi+320+8]
mov [edi+320+8],eax
mov eax,[esi+320+12]
mov [edi+12+320],eax

mov eax,[esi+320*2]
mov [edi+320*2],eax
mov eax,[esi+320*2+4]
mov [edi+320*2+4],eax
mov eax,[esi+320*2+8]
mov [edi+320*2+8],eax
mov eax,[esi+320*2+12]
mov [edi+12+320*2],eax

mov eax,[esi+320*3]
mov [edi+320*3],eax
mov eax,[esi+320*3+4]
mov [edi+320*3+4],eax
mov eax,[esi+320*3+8]
mov [edi+320*3+8],eax
mov eax,[esi+320*3+12]
mov [edi+12+320*3],eax


mov eax,[esi+320*4]
mov [edi+320*4],eax
mov eax,[esi+320*4+4]
mov [edi+320*4+4],eax
mov eax,[esi+320*4+8]
mov [edi+320*4+8],eax
mov eax,[esi+320*4+12]
mov [edi+12+320*4],eax

mov eax,[esi+320*5]
mov [edi+320*5],eax
mov eax,[esi+320*5+4]
mov [edi+320*5+4],eax
mov eax,[esi+320*5+8]
mov [edi+320*5+8],eax
mov eax,[esi+320*5+12]
mov [edi+12+320*5],eax

mov eax,[esi+320*6]
mov [edi+320*6],eax
mov eax,[esi+320*6+4]
mov [edi+320*6+4],eax
mov eax,[esi+320*6+8]
mov [edi+320*6+8],eax
mov eax,[esi+320*6+12]
mov [edi+12+320*6],eax

mov eax,[esi+320*7]
mov [edi+320*7],eax
mov eax,[esi+320*7+4]
mov [edi+320*7+4],eax
mov eax,[esi+320*7+8]
mov [edi+320*7+8],eax
mov eax,[esi+320*7+12]
mov [edi+12+320*7],eax


mov eax,[esi+320*8]
mov [edi+320*8],eax
mov eax,[esi+320*8+4]
mov [edi+320*8+4],eax
mov eax,[esi+320*8+8]
mov [edi+320*8+8],eax
mov eax,[esi+320*8+12]
mov [edi+12+320*8],eax


mov eax,[esi+320*9]
mov [edi+320*9],eax
mov eax,[esi+320*9+4]
mov [edi+320*9+4],eax
mov eax,[esi+320*9+8]
mov [edi+320*9+8],eax
mov eax,[esi+320*9+12]
mov [edi+12+320*9],eax


mov eax,[esi+320*10]
mov [edi+320*10],eax
mov eax,[esi+320*10+4]
mov [edi+320*10+4],eax
mov eax,[esi+320*10+8]
mov [edi+320*10+8],eax
mov eax,[esi+320*10+12]
mov [edi+12+320*10],eax


mov eax,[esi+320*11]
mov [edi+320*11],eax
mov eax,[esi+320*11+4]
mov [edi+320*11+4],eax
mov eax,[esi+320*11+8]
mov [edi+320*11+8],eax
mov eax,[esi+320*11+12]
mov [edi+12+320*11],eax


mov eax,[esi+320*12]
mov [edi+320*12],eax
mov eax,[esi+320*12+4]
mov [edi+320*12+4],eax
mov eax,[esi+320*12+8]
mov [edi+320*12+8],eax
mov eax,[esi+320*12+12]
mov [edi+12+320*12],eax


mov eax,[esi+320*13]
mov [edi+320*13],eax
mov eax,[esi+320*13+4]
mov [edi+320*13+4],eax
mov eax,[esi+320*13+8]
mov [edi+320*13+8],eax
mov eax,[esi+320*13+12]
mov [edi+12+320*13],eax


mov eax,[esi+320*14]
mov [edi+320*14],eax
mov eax,[esi+320*14+4]
mov [edi+320*14+4],eax
mov eax,[esi+320*14+8]
mov [edi+320*14+8],eax
mov eax,[esi+320*14+12]
mov [edi+12+320*14],eax


mov eax,[esi+320*15]
mov [edi+320*15],eax
mov eax,[esi+320*15+4]
mov [edi+320*15+4],eax
mov eax,[esi+320*15+8]
mov [edi+320*15+8],eax
mov eax,[esi+320*15+12]
mov [edi+12+320*15],eax

ret
reetrertertert3: ;affichage d'un oeuf

aff_oeuf

jmp reetrertertert

reetrertertert2: ;affichage d'une explosion de bonus...

sub edi,11*320+6
SPRITE_27_31

jmp reetrertertert
affiche_sprites endp




;load proc near
; xor eax,eax
; mov al,00h  ;ouverture du fichier pour lecture.
; mov ah,03dh
; mov edx,offset fichier
; int 21h
; jc erreur_filec;saute si carry=1
;
; mov ebx,eax
; mov ah,03fh
; mov ecx,064000
; mov edx,offset buffer
; int 21h
;
; mov ah,03eh
; int 21h
;ret
                     ; DOS INT 21h

;call affsigne
;ret
;load endp


beuh proc near
push ds
mov ax,fs  ;SOURCE...
mov ds,ax  ;
mov es,ax
mov esi,0
mov edi,614400
mov ecx,76800
rep movsd
pop ds
ret
beuh endp

aff_page proc near ;affiche en ram video ce k'il y a a : FS:ESI
                   ;ENTREE : ESI

push ds

xor edi,edi

mov ax,fs  ;SOURCE...
mov ds,ax  ;

xor bx,bx ;pour l'int.
xor dx,dx

call change_page
push edi
mov ecx,016384
rep movsd
pop edi
call change_page
push edi
mov ecx,016384
rep movsd
pop edi
call change_page
push edi
mov ecx,016384
rep movsd
pop edi
call change_page
push edi
mov ecx,016384
rep movsd
pop edi
call change_page
push edi
mov ecx,45056/4
rep movsd
pop edi


pop ds
ret
change_page:
;mov     dx,bp ;numero de la fenetre ;ax
;xor     bx,bx
mov     ax,4f05h
int     10h
inc dx ;bp
ret
aff_page endp


;copie_page proc near ;copie dans buffer ce k'il y a a : FS:ESI
;PUSHALL
;mov ax,ds
;mov es,ax
;mov ax,fs
;mov ds,ax
;mov edi,offset buffer
;mov ecx,64000/4
;rep movsd
;
;POPALL
;ret
;copie_page endp

aff_page2 proc near ;affiche en ram video ce k'il y a a dans le buffer

RAMBUFFER

;PUSH ESI
;mov esi,offset buffer
;ram
;POP ESI
RET

;PUSHALL
;
;cmp [affiche_pal],1 ;!!! sauf si on eteint la pal...
;jne erertrte
;POPALL
;ret
;erertrte:
;
;xor edi,edi
;
;;mov ax,fs  ;SOURCE...
;;mov ds,ax  ;
;
;mov esi,offset buffer
;
;mov ecx,320*200/4
;rep movsd
;
;POPALL
;ret

aff_page2 endp

FILEERROR MACRO
local erreur_filec
 jnc  erreur_filec ;saute si carry=1


       mov ax,3h
        int 10h
        lea edx,loaderror
        mov ah,9
        int 21h
        mov bl,0100B ;rouge
        mov bh,10000000B ;indique clignotement
        call last_color

        mov ax,4c00h                    ; AH=4Ch - Exit To DOS
        int 21h

        erreur_filec:
ENDM

load_pcx proc near ; ecx: offset dans le fichier.
                   ; edx: offset nom du fichier
                   ; edi: viseur dans données ou ca serra copié (ax:)
                   ; ebx: nombre de pixels dans le pcx

pushad
push es ds

mov [load_pcx_interne],ebx


 mov es,ax

 xor eax,eax
 mov al,00h  ;ouverture du fichier pour lecture.
 mov ah,03dh
 int 21h
 FILEERROR

mov [load_handle],eax

;... deplacement a l'interieur du fichier rmd ...

push ecx ;(1)

mov ebx,[load_handle]
mov ah,042h
mov al,00h ;debut du fichier
mov dx,cx
shr ecx,16
;dans cx:dx deplacement a l'interieur du fichier
int 21h
FILEERROR
;...lecture du fichier...

 mov ebx,[load_handle]
 mov ah,03fh
 mov ecx,0FFFFh
 mov edx,offset buffer
 int 21h
FILEERROR
pop eax ;(1)


push ebx
mov ebx,dword ptr [buffer]
BIGENDIANPATCH ebx
add eax,ebx
pop ebx

sub eax,768

push eax ;(1)

;xor edi,edi

xor ebx,ebx ;nombre de pixel k'on a affiche
xor ecx,ecx

mov esi,offset buffer+128

encore_un_pixel:

cmp ebx,[load_pcx_interne]
jnb cestfini

lodsb

cmp esi,offset buffer+0ffffh
jne coke
call charge_encore
mov esi,offset buffer
coke:

cmp al,192
jb non_c_un_octet_seul
and al,0111111B

movzx cx,al ;non signe... 8 -> 16 bits

lodsb

cmp esi,offset buffer+0ffffh
jne cok
call charge_encore
mov esi,offset buffer
cok:

viennes:
stosb
inc ebx    ;nombre de pixels k'on a affiches.
dec cx
jnz viennes

jmp encore_un_pixel

non_c_un_octet_seul:
stosb
inc ebx     ;nombre de pixels k'on a affiches.

jmp encore_un_pixel

cestfini:

;.... plus k'a recopier la palette...

;mov ax,c
;mov es,ax
;mov ds,ax
mov ebx,[load_handle]
;;mov eax,0 ;-768 ;259995 ;768

pop eax ;(1) !!
;
mov dx,ax
shr eax,16
mov cx,ax
mov ah,042h
mov al,00h
int 21h
FILEERROR

;
;push dx
;mov ax,c
;mov es,ax
;mov ds,ax
mov ebx,[load_handle]
mov ah,03fh
mov cx,0768
mov edx,offset pal
int 21h
;pop dx
;
;;...............convertis la palette...
;
;
;;dans cx:dx deplacement a l'interieur du fichier
;
;mov ax,c
;mov es,ax
;mov ds,ax
         mov esi,offset pal
;         mov di,offset pal
mov cx,768
xor ax,ax
rtrttr:
mov al,[esi]
shr al,2
mov [esi],al
inc esi
dec cx
jnz rtrttr
;
;...fermeture fichier...
mov ebx,[load_handle]
mov ah,03eh
int 21h
FILEERROR

pop ds es
popad
ret
load_pcx endp

load_raw proc near ; ecx: offset dans le fichier.
                   ; edx: offset nom du fichier
                   ; edi: viseur dans données ou ca serra copié (ax:)
                   ; ebx: nombre de pixels dans le pcx

pushad
push es ds

 xor eax,eax
 mov al,00h  ;ouverture du fichier pour lecture.
 mov ah,03dh
 int 21h
jnc retyryurttyutyutyuutyyuiiyuuiyuiy
mov dl,13
mov ah,2
int 21h
lea edx,suite2
mov ah,09h
int 21h
        mov bl,4 ;rouge
        mov bh,10000000B ;indique clignotement
        call last_color
        mov ax,4c00h                    ; AH=4Ch - Exit To DOS
        int 21h                         ; DOS INT 21h
retyryurttyutyutyuutyyuiiyuuiyuiy:

mov [load_handle],eax

mov ebx,[load_handle]
mov ah,042h
mov al,00h ;debut du fichier
mov dx,cx
shr ecx,16
int 21h

 mov ebx,[load_handle]
 mov ah,03fh
 mov ecx,064000
                   ; edi: viseur dans données ou ca serra copié (ax:)
push ds
push fs
pop  ds
 mov edx,edi
 int 21h
pop ds

mov ebx,[load_handle]
mov ah,03eh
int 21h

pop ds es
popad
ret
load_raw endp


charge_encore proc near

push ds ax es ds ebx cx dx
mov ebx,[load_handle]
mov ah,03fh
mov cx,0FFFFh
mov edx,offset buffer
int 21h
pop  dx cx ebx ds es ax ds

ret
charge_encore endp

;pal          db  768 dup (?)  ;pal  de l'émulateur.
;pal_affiche db 768 dup (0)   ;pal k'on affiche...

;affiche_pal  db 0             ; 1: vas de la palette au noir (ne plus afficher
;                              ;                               d'écran !!!)
;                              ;
;                              ; 2: va du noir a la palette
;                              ; 0: ne fait rien...


pal_visage proc near
PUSHALL
;call noping
;call noping
;call noping
;call noping
;call noping
;call noping
;call noping
;call noping
;call noping
;call noping
;call noping
;call noping

cmp [affiche_pal],0
jne histoire
rty:
POPALL
ret
histoire:

push ds
pop  es

cmp [affiche_pal],1
jne zorrro

;affiche_pal  db 0             ; 1: vas de la palette au noir (ne plus afficher
;                              ;                               d'écran !!!)

;------------
xor bp,bp
mov dx,4
reeeeee:
;mov esi,offset pal
mov esi,offset pal_affiche
mov cx,768
rchanger:
cmp byte ptr [esi],0
je pareil
dec byte ptr [esi]
jmp pas_pareil
pareil:
inc bp
pas_pareil:
inc esi
dec cx
jnz rchanger
dec dx
jnz reeeeee

cmp bp,768*4
jne erterterterrterte
mov [affiche_pal],2
erterterterrterte:

call affpal
POPALL
ret

zorrro:

xor bp,bp
mov dx,4
yreeeeee:

mov edi,offset pal

;cmp byte ptr [ordre2],'' ;uniqUEMENT si on est dans le jeu.
;jne terterertrteertyerertrteterter

cmp byte ptr [ordre],'S'
jne rezterterertrteertyerertrteterter
cmp [master],0
jne opiopiioiouuiiuiuiuooo
cmp [pic_time],0
je opiopiioiouuiiuiuiuooo
lea edi,pal_pic
;cmp kel_pic_intro,1
;jne opiopiioiouuiiuiuiuooo
;lea edi,pal_pic2
opiopiioiouuiiuiuiuooo:
rezterterertrteertyerertrteterter:

; si on est pas dans le menu
cmp byte ptr [ordre],'S'
je terterertrteertyerertrteterter
cmp byte ptr [ordre2],''
jne terrteterertterterertrteertyerertrtetertererer
lea edi,pal_jeu
terrteterertterterertrteertyerertrtetertererer:
cmp byte ptr [ordre2],'V'
jne terrteterertterterertrteertyerertrteterterererr
lea edi,pal_jeu
terrteterertterterertrteertyerertrteterterererr:


cmp byte ptr [ordre2],'V'
jne terrteterertterterertrteertyerertrtetertererereErr
lea edi,pal_vic
terrteterertterterertrteertyerertrtetertererereErr:


cmp byte ptr [ordre2],'Z'
jne terrteterertterterertrteertyerertrtetertererereE
lea edi,pal_med
terrteterertterterertrteertyerertrtetertererereE:
cmp byte ptr [ordre2],'D'
jne tyr2trtyrtyrtyrtyrtyterterertrteert
lea edi,pal_draw
tyr2trtyrtyrtyrtyrtyterterertrteert:
terterertrteertyerertrteterter:


cmp pic_de_tout_debut,1
jne ereetrtrtrtrteeete
lea edi,pal_pic2
ereetrtrtrtrteeete:

mov esi,offset pal_affiche
mov cx,768
yrchanger:
mov al,byte ptr [edi]
cmp byte ptr [esi],al
je ypareil
inc byte ptr [esi]
jmp ypas_pareil
ypareil:
inc bp
ypas_pareil:
inc edi
inc esi
dec cx
jnz yrchanger
dec dx
jnz yreeeeee

cmp bp,768*4
jne yerterterterrterte
mov [affiche_pal],0
yerterterterrterte:

call affpal

POPALL
ret
endp

;get_pal_ansi proc near
;PUSHALL
;   mov   dx,3c7h
;   XOR   al,al
;   out   dx,al
;   mov   dx,3c9h
;push ds
;pop es
;lea edi,pal_txt_debut
;         mov cx,256*3
;         u@@saaccvaaaax:
; in al,dx
;stosb
;   dec cx
;         JNZ  u@@saaccvaaaax
;POPALL
;ret
;get_pal_ansi endp

affpal      proc near
    pushad

         mov   esi,offset pal_affiche
     mov   dx,3c8h
     XOR   al,al
     out   dx,al
     mov   dx,3c9h
         mov cx,256*3
         @@saaccvaaaax:
     LODSB
     out   dx,al
     dec cx
         JNZ  @@saaccvaaaax
   popad
   ret
affpal      endp

affpal2      proc near
    pushad

;         mov   esi,offset pal_affichée
     mov   dx,3c8h
     XOR   al,al
     out   dx,al
     mov   dx,3c9h
         mov cx,256*3
         a@@saaccvaaaax:
     LODSB
     out   dx,al
     dec cx
         JNZ  a@@saaccvaaaax
   popad
   ret
affpal2      endp

copie_le_fond proc near
PUSHALL

dec [attente]

cmp [attente],0
jne erteteteerre

add [viseur_sur_fond],4
mov [attente],max_attente

cmp [terrain],2     ; eau...
jne yertertertertertutyoooooortyyrt
mov [attente],min_attente    ;
yertertertertertutyoooooortyyrt:


erteteteerre:
mov eax,4*4

cmp [terrain],2 ;       db 2        ; 1:fete, 2: neige...
jne yertertertertertutyoooooo
mov eax,3*4
yertertertertertutyoooooo:

mov ebx,[viseur_sur_fond]
cmp  ebx,eax ;4 [nombre_de_fond]
jb erterertyurttyu
mov [viseur_sur_fond],0
xor ebx,ebx
erterertyurttyu:

push ebx
mov bl,terrain
dec bl
shl ebx,2
mov esi,[ebx+kelle_offset_fond]
pop ebx

mov esi,[esi+ebx]

;cmp [terrain],2 ;       db 2        ; 1:fete, 2: neige...
;jne yertertertertert
;mov esi,[adresse_des_fonds_neige+ebx]
;yertertertertert:
;
;cmp [terrain],3 ;       db 2        ; 1:fete, 2: neige...
;jne yertertertertert1
;mov esi,[adresse_des_fonds_hell+ebx]
;yertertertertert1:
;
;cmp [terrain],4 ;       db 2        ; 1:fete, 2: neige...
;jne yertertertertert2
;mov esi,[adresse_des_fonds_foret+ebx]
;yertertertertert2:
;
;cmp [terrain],5 ;       db 2        ; 1:fete, 2: neige...
;jne yertertertertert2r
;mov esi,[adresse_des_fonds_nuage+ebx]
;yertertertertert2r:
;
;
;
;cmp [terrain],1 ;       db 2        ; 1:fete, 2: neige...
;jne rertertertertert
;mov esi,[adresse_des_fonds+ebx]
;rertertertertert:



;===== affiche en ram video ce k'il y a a : FS:ESI
;      ENTREE : ESI
ramesi
copyblock

POPALL
ret
copie_le_fond endp


copie_le_fond_draw proc near
PUSHALL

;adresse_des_fonds dd 0,64000,128000
;nombre_de_fond    dd 3*2
;viseur_sur_fond   dd 0
;attente               db 0
;max_attente           db 0

dec [attente]

cmp [attente],0
jne yerteteteerre

add [viseur_sur_draw],4
mov [attente],max_attente

yerteteteerre:

mov ebx,[viseur_sur_draw]
cmp  ebx,[nombre_de_draw]
jne yerterertyurttyu
mov [viseur_sur_draw],0
xor ebx,ebx
yerterertyurttyu:

mov esi,[adresse_des_draws+ebx]

;===== affiche en ram video ce k'il y a a : FS:ESI
;      ENTREE : ESI
ramesi
copyblock

POPALL
ret
copie_le_fond_draw endp


copie_le_fond_vic  proc near
PUSHALL

dec [attente]

cmp [attente],0
jne iyyerteteteerre

;mov edi,704000 ; 128000  ;307200
add [viseur_sur_vic],4
mov [attente],max_attente4

iyyerteteteerre:

mov ebx,[viseur_sur_vic]
cmp  ebx,[nombre_de_vic]
jne iyerterertyurttyu
mov [viseur_sur_vic],0
xor ebx,ebx
iyerterertyurttyu:

mov esi,[adresse_des_vic+ebx]

;===== affiche en ram video ce k'il y a a : FS:ESI
;      ENTREE : ESI
ramesi
copyblock
POPALL
PUSHALL
push ds
pop   es
;mov esi,offset donnee4+9*4
;mov ecx,9
;rep movsd

;mov esi,dword ptr [donnee4+9*4]
;
;mov esi,640000 ; 128000  ;307200

inc dword ptr [changementZZ]

supreme_victory_group:
mov eax,[nombre_de_dyna]
mov edi,[latest_victory]
mov ebx,[team+edi]
xor edi,edi
xor ecx,ecx

supreme_victory_group_winners_loop:
cmp ebx,[team+edi]
jne supreme_victory_group_winners_next
add ecx,16+8

supreme_victory_group_winners_next:
add edi,4
dec eax
jne supreme_victory_group_winners_loop

mov edx,320
sub edx,ecx
shr edx,1
add edx,57*320
xor ecx,ecx
mov eax,[nombre_de_dyna]

supreme_victory_group_loop:
cmp ebx,[team+ecx]
jne supreme_victory_group_next

push eax
push ebx
push ecx
push edx
test ecx,0100b
jne supreme_victory_group_sprite
add edx,3*320

supreme_victory_group_sprite:
lea edi,[donnee4+9*4]
mov esi,[ooo546+ecx]
mov ebx,[liste_couleur+ecx]
movzx eax,word ptr [ebx+0*2]
add eax,esi
stosd
movzx eax,word ptr [ebx+1*2]
add eax,esi
stosd
movzx eax,word ptr [ebx+2*2]
add eax,esi
stosd
movzx eax,word ptr [ebx+3*2]
add eax,esi
stosd
shr ecx,1
mov ax,[dummy1392+ecx]
stosb
mov ax,[dummy1393+ecx]
stosb
shl ecx,1

mov ebx,[changementZZ]
and ebx,000110000B
shr ebx,2
mov esi,[donnee4+9*4+ebx]
mov edi,edx
xor cx,cx
mov cl,[donnee4+9*4+4*4+1] ;nombre de colonnes.
xor bx,bx
mov bl,[donnee4+9*4+4*4] ;nb lignes

mov dl,[donnee4+8+ebp] ;1er bit: clignotement ???
and dl,01B

push ds
push fs
pop  ds
call affiche_bomby2
pop  ds

pop edx
pop ecx
pop ebx
pop eax
add edx,16+8

supreme_victory_group_next:
add ecx,4
dec eax
jnz supreme_victory_group_loop

POPALL
ret
copie_le_fond_vic endp


copie_le_fond_med proc near

PUSHALL

SOUND

;adresse_des_fonds dd 0,64000,128000
;nombre_de_fond    dd 3*2
;viseur_sur_fond   dd 0
;attente               db 0
;max_attente           db 0

mov esi,64000*7                  ;[adresse_des_draws+ebx]
cmp [team3],1
jne pas_color
mov esi,1582080+64000
pas_color:
cmp [team3],2
jne pas_g
mov esi,1582080+64000*2
pas_g:

;===== affiche en ram video ce k'il y a a : FS:ESI
;      ENTREE : ESI
ramesi
copyblock

;---- copie les noms des joueurs
PUSHALL
push ds
pop es

mov ebx,offset briques
mov [viseur_couleur],0
mov edi,offset buffer
mov ecx,8
xor edx,edx
pppppppgoeger:
push edi
;viseur_namec dd 10+(69)*320,10+(69+9)*320,10+(43+42*2)*320,10+(43+42*3)*320
cmp [team3],1
jne pas_c3
add edi,[viseur_namec+edx]
jmp ihjhuihui
pas_c3:
cmp [team3],2
jne pas_g3
add edi,[viseur_nameg+edx]
jmp ihjhuihui
pas_g3:
add edi,[viseur_name+edx]
ihjhuihui:
;------------- affiche un nom de joueur...--
PUSHALL
call affiche_un_caractere
POPALL
add edi,8
inc ebx
PUSHALL
call affiche_un_caractere
POPALL
add edi,8
inc ebx
PUSHALL
call affiche_un_caractere
POPALL
inc [viseur_couleur]
add ebx,2 ;affichae pas l'espace
;-------------------------------------------
pop edi
add edx,4
;add ebx,4
dec ecx
jnz pppppppgoeger

POPALL
;-------------------

POPALL

PUSHALL

;------- copie les médailles ---

;victoires dd 8 dup (?)
;viseur pour on place la premiere médaille pour chacun des 8 joueurs.
;
;viseur_victory dd 44+44*320,44+86*320,44+128*320,44+170*320
;               dd 205+45*320,205+86*320,205+128*320,205+170*320
;latest_victory dd ?
;offset_medaille dw 23*0,23*1,23*2,23*3,23*4,23*5,23*6,23*7,23*8,23*9,23*10,23*11,23*12
;                dw 23*320+23*0,23*320+23*1,23*320+23*2
push ds
pop  es

;mov edi,offset buffer
;mov ecx,320
;mov eax,54501015
;rep stosd

mov esi,64000*8

xor ebx,ebx

mov ax,fs
;;dans ax: source
mov ds,ax

;add viseur sur la piece !!!
mov ebx,es:[changementZZ]
and ebx,0111100B
shr ebx,1

inc dword ptr es:[changementZZ]

xor ebp,ebp
mov edi,offset buffer
ertrterteterter:
push edi

mov ecx,dword ptr es:[donnee4+ebp] ;victoires
or ecx,ecx
jz ertertertertertertert

cmp ecx,5
jb rerterteertrte
mov ecx,5
rerterteertrte:


;-----
erertererrteert:
push edi esi
xor eax,eax

;mov ebx,es:[changement]
;and ebx,0111100B
;shr ebx,1

;add ebx,ebx
mov ax,word ptr es:[offset_medaille+ebx]
add esi,eax

cmp es:[team3],1
jne pas_c32
add edi,es:[viseur_victoryc+ebp]
jmp ihjhuihui2
pas_c32:
cmp es:[team3],2
jne pas_c32r
add edi,es:[viseur_victoryg+ebp]
jmp ihjhuihui2
pas_c32r:
add edi,es:[viseur_victory+ebp]
ihjhuihui2:

;--- clignotement ---
cmp ecx,1
jne eertterrtrteterert

draw_skynet_team_medals:
cmp es:[team3_sauve],4
jne check_victory_medal_player

mov eax,es:[latest_victory]
mov eax,es:[team+eax]
cmp eax,es:[team+ebp]
je draw_win_victory_medal

check_victory_medal_player:
cmp dword ptr es:[donnee4+4*8],ebp
jne eertterrtrteterert

draw_win_victory_medal:
mov esi,64000*8 ;de face uniquement

;briques dw 1+19*13*2 dup (?)  ;nombre de brique, source de la brique, destination
;                              ;dans buffer video
;                              ;si on est dans 'Z' médaille céremony
;                              ;les noms de chaque joueur. 8x4 octets.
;
;                   ;+ 1 db= faut afficher la brike ki clignote ou pas???
cmp byte ptr es:[briques+8*4],1
je ertterrtrteterert
;test dword ptr es:[changementZZ],0000110000B
;jnz  eertterrtrteterert
;jmp ertterrtrteterert
eertterrtrteterert:
call aff_sprite ;// c'est le sprite pour les victoire ou autre ignorer.
ertterrtrteterert:
;--- clignotement ---

pop  esi edi

add edi,23

add ebx,2*2
and ebx,31

dec ecx
jnz erertererrteert
;-----
ertertertertertertert:


pop edi
add ebp,4
cmp ebp,4*8
jne ertrterteterter

POPALL
ret
aff_sprite:
PUSH ecx ebx esi
mov ecx,22
ertertertrteert:
mov ebx,22
concert:
lodsb
or al,al
jz ertertertrte
mov byte ptr es:[edi],al
ertertertrte:
inc edi
dec ebx
jnz concert
add edi,320-22
add esi,320-22
dec ecx
jnz ertertertrteert
pop  esi ebx ecx
ret
copie_le_fond_med endp


inst_clavier proc near
PUSHALL

;2.14 - Function 0200h - Get Real Mode Interrupt Vector:
;-------------------------------------------------------
;  Returns the real mode segment:offset for the specified interrupt vector.
;In:
;  AX     = 0200h
;  BL     = interrupt number
;Out:
;  always successful:
;    carry flag clear
;    CX:DX  = segment:offset of real mode interrupt handler
;Notes:
;) The value returned in CX is a real mode segment address, not a protected
;  mode selector.

;mov ax,0200h
;mov bl,9
;int 31h
;
;mov word ptr [clavier_old_int],dx
;mov word ptr [clavier_old_int+2],cx

;2.15 - Function 0201h - Set Real Mode Interrupt Vector:
;-------------------------------------------------------
;  Sets the real mode segment:offset for the specified interrupt vector.
;In:
; AX     = 0201h
;  BL     = interrupt number
;  CX:DX  = segment:offset of real mode interrupt handler

;offset_2_adresse_physique proc near ;source ds:esi
;                                    ;adresse physique (dx:ax)

;mov esi,offset HANDLER9
;call offset_2_adresse_physique
;mov cx,dx
;mov dx,ax
;mov ax,201h
;int 31h

;2.18 - Function 0204h - Get Protected Mode Interrupt Vector:
;------------------------------------------------------------
;
;  Returns the address of the current protected mode interrupt handler for the
;specified interrupt.
;
;In:
;  AX     = 0204h
;  BL     = interrupt number
;
;Out:
;  always successful:
;    carry flag clear
;    CX:EDX = selector:offset of protected mode interrupt handler

;  AX     = 0204h
;  BL     = interrupt number
;
;Out:
;  always successful:
;    carry flag clear
;    CX:EDX = selector:offset of protected mode interrupt handler

mov cx,cs
mov edx,offset handler10   ;IGNORE
mov ax,0205h
mov bl,9
int 31h

POPALL
ret
inst_clavier endp

;de_inst_clavier proc near
;PUSHALL
;
;mov dx,word ptr [clavier_old_int]
;mov cx,word ptr [clavier_old_int+2]
;
;mov ax,201h
;int 31h
;
;
;POPALL
;ret
;
;de_inst_clavier endp

;db 0b8h
;sisisis dw ?




HANDLER10 PROC NEAR ;detourtenement int 9h (procedure k'on rajoute devant l'int.)
PUSHF
PUSHALL

mov ecx,132456h
mov edx,132456h
db 0b8h  ;IGNORE
merdo dd ?                    ;IGNORE
;2144
mov ds,ax

;mov temps_avant_demo,ttp



xor eax,eax
in al,60h
;call affsigne
;mov [last_sucker],al
;mov [last_sucker],al
test al,128
jnz ureertrteertert2

ureertrteertert2:

mov edi,offset clavier

cmp al,225         ;
jne retertert_specialye
mov [clavier_stuff2],2

cmp action_replay,0
jne retertert_specialye

mov [pause],1
jmp tttttttttoooooi
retertert_specialye:

cmp al,224         ;
jne retertert_special
mov [clavier_stuff],1
jmp tttttttttoooooi
retertert_special:

;------------- special pause -----------
cmp [clavier_stuff2],0
je reterrteertertter
dec [clavier_stuff2]
;;;;;;;;jnz tttttttttoooooi
;;;;;;;;;;;mov [last_sucker],110 ;code pause...
jmp tttttttttoooooi
reterrteertertter:
;---------------------

cmp [clavier_stuff],1
jne pas_extanded
mov [clavier_stuff],0
;;-+----------------
;cmp al,42 ;cas particulier.. les 224,42 on s'en tappe !!!
;je tttttttttoooooi
;;-+------------

;---c as particulier pause !!!!
cmp al,70
jne pas_poauser
mov [pause],1
 pas_poauser:
;--------


xor ebx,ebx
CMP AL,128
JB uTOU
and al,127
mov bl,al
mov al,[clavier_extanded+ebx]
or al,al           ;si non prevu... fait rien...
je tttttttttoooooi

or al,128
jmp pas_extanded
uTOU:
mov bl,al
mov al,[clavier_extanded+ebx]
;cmp al,42 ;cas particulier.. les 224,42 on s'en tappe !!!
or al,al           ;si non prevu... fait rien...
je tttttttttoooooi

pas_extanded:

CMP AL,128
JB uTOUCHE_APPUYEE
AND AL,01111111B
ADD eDI,eAX
MOV byte ptr [eDI],0
jMP uBE_ALL
uTOUCHE_APPUYEE:
add edi,eax
;;-----------------------***--------------**
;;touches_  dd 114,115,112,113,82,83,0, -1
;;          dd 20,21,16,30,57,15,0,     -1
;push ebx edi
;xor ebx,ebx
;encpoooe:
;cmp [touches_+ebx+7*4],-1
;;jne pas_active
;cmp [touches_+ebx],eax
;je cceluila
;cmp [touches_+ebx+4],eax
;je cceluila
;cmp [touches_+ebx+8],eax
;je cceluila
;cmp [touches+ebx+12],eax
;je cceluila
;
;jmp pas_active
;cceluila:
;mov edi,offset clavier
;add edi,[touches_+ebx]
;MOV byte ptr [eDI],0
;
;mov edi,offset clavier
;add edi,[touches_+ebx+4]
;;MOV byte ptr [eDI],0
;
;mov edi,offset clavier
;add edi,[touches_+ebx+8]
;MOV byte ptr [eDI],0
;
;mov edi,offset clavier
;add edi,[touches_+ebx+12]
;MOV byte ptr [eDI],0
;
;pas_active:
;add ebx,8*4
;cmp ebx,(8*4)*8
;jne encpoooe
;pop edi ebx
;;------------********---------************-
MOV byte ptr [eDI],1
;mov [last_sucker],al
uBE_ALL:

tttttttttoooooi:

cmp eax,1
jne uertterertert
cmp [attente_nouveau_esc],0
jne uertterertert
mov [sortie],1
uertterertert:


uoitreterrtyrty:

mov byte ptr [une_touche_a_telle_ete_pressee],1 ;et oui...
mov al,20h
out 20h,al

POPALL
POPF
iret

handleR10 ENdP


;donnee2 dd 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
;        dd 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
;        dd 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
;        dd 0,0,0,0     ,0,0   ;4eme joeur d'un ordy

;mov esi,offset donnee2 ;si joeur 1


controle proc near ;utilise par les slavers et les masters

cmp taille_exe_gonfle,0
jne dfgdf222gfghjktrhtkrjjrtyhjkrtyjklrty
;mov byte ptr [donnee2+8*7+2],0
ret
dfgdf222gfghjktrhtkrjjrtyhjkrtyjklrty:

PUSHALL
                 ;prépare le packet qu'on va transmettre en informant
                 ;les touches ke l'on presse actuellement
                 ;


;nbe_bomber_locaux dd 2 ;nombre de bombers locaux
;
;bomber_locaux dd 0,1,0,0 ;mode de controle pour les bombermans locaux.
;;0 key droit
;;1 keyb gauche

;--------- efface le packet...
push ds
pop  es




xor eax,eax
mov edi,offset donnee2
mov ecx,touches_size
rep stosb
;----------------------------

mov ecx,8 ;[nbe_bomber_locaux] ;ceci ne correspond pas a l'ordre des dyna
                               ; juste les 8 dyna possilbe sur 1 becane
mov esi,offset donnee2
mov edi,offset touches_  ;mode de control
;xor ebp,ebp
;
;mov ah,02h ;SUPER_SIGNE2 DB 0
;mov dl,13
;int 21h

ertyertyjyuiyuiyuiiyu:
push ecx

push esi
mov dword ptr [esi],0 ;on efface le dernier packet
mov word ptr [esi+4],0
push edi
cmp dword ptr [edi+7*4],-1 ;ke si joueur en action (via setup)
jne retertertrtertetyyrtuui

call controle_joueur_fleche
retertertrtertetyyrtuui:
pop edi
pop esi

add esi,7 ;6 ;7

add edi,8*4 ;mode de control
;add ebp,4
pop ecx
dec ecx
jnz ertyertyjyuiyuiyuiiyu


cmp taille_exe_gonfle,0
je zappelesmachins

;return
cmp byte ptr [clavier+28],1
jne erertertertp
mov byte ptr [donnee2+8*7],1
erertertertp:

;esc
cmp byte ptr [clavier+1],1
jne erertertertpt
mov byte ptr [donnee2+8*7+1],1
erertertertpt:

cmp byte ptr [une_touche_a_telle_ete_pressee],1
jne erertertertptEE
mov byte ptr [donnee2+8*7+2],1
erertertertptEE:
mov byte ptr [une_touche_a_telle_ete_pressee],0
zappelesmachins:

POPALL
ret
controle endp


start_cpu_player proc near
PUSHALL
mov esi,offset differents_offset_possible+4*8
xor eax,eax
mov al,nb_ai_bombermen
shl eax,2
add esi,eax

mov ebp,nombre_de_dyna
cmp ebp,8
je exit_function
shl ebp,2
mov eax,[esi+ebp]
mov [control_joueur+ebp],eax

inc nombre_de_dyna
inc nb_ai_bombermen
exit_function:
POPALL
ret
start_cpu_player endp

menu_intelligence proc near

PUSHALL

SOUND_FAC fx

;n al,60h
;cmp al,57
;jne reterrterterte2
;mov byte ptr [ordre],''
;reterrterterte2:
;cmp byte ptr [clavier+1],1
;jne erertertertpt
;cmp byte ptr [total_t+6*4+1],1


;------------- ordre du master --------------------------

;******************************************************

cmp [nombre_de_dyna],0          ;
jnz rtbrtyjkrtklrtyrtyrtyrty    ; dont go to demo if someone is reg...

dec temps_avant_demo
jnz rtbrtyjkrtklrtyrtyrtyrty
mov temps_avant_demo,ttp2 ;temps_avant_demo2/10
jmp rtrtytyutyutyutyuyuttyuyuttyuyutyuyuttyuyuttyuyut
rtbrtyjkrtklrtyrtyrtyrty:

;cmp byte ptr [clavier+88],1 ;F12
;jne retyeyutyuutyyutyutyuioodfgdfgdfggdf
;
cmp action_replay,2
je rtrtytyutyutyutyuyuttyuyuttyuyutyuyuttyuyuttyuyut

jmp retyeyutyuutyyutyutyuioodfgdfgdfggdf

rtrtytyutyutyutyuyuttyuyuttyuyutyuyuttyuyuttyuyut:

        ;on ne passe pas en mode demo si on est sur le 386...
       ; cmp [assez_de_memoire],1
       ; je retyeyutyuutyyutyutyuioodfgdfgdfggdf



;=========== restauration/sauvegarde replay ===========
;******** ACTION REPLAY--------------------
; si play
;cmp action_replay,2 ; play,recup...
;jne pashjktrkhjerterttyrr
;mov edx,dword ptr fs:[1966080+TAILLE_HEADER_REC-5] ;rotation, offet 1 dans le header !
PUSHALL

; on joue une partie


;differentesply dd 1966080+64000,1966080+64000*2,1966080+64000*3,1966080+64000*4,1966080+64000*5

mov ebx,differentesply2

add differentesply2,4
cmp differentesply2,4*nb_sply
jne ertyertyuityu
mov differentesply2,0
ertyertyuityu:

mov esi,[differentesply+ebx]
mov replayer_saver4,esi

;mov ax,fs
;mov ds,ax
;mov es,ax

;mov eax,fs:[1966080+TAILLE_HEADER_REC-9] ;variable changement

;mov edi,1966080
;;mov esi,1966080+64000
;mov ecx,16000
;rep movsd
POPALL
;pashjktrkhjerterttyrr:
;=======

;initialisation des pointeurs..
mov esi,replayer_saver4
mov replayer_saver5,1  ;// byte ptr fs:[esi+TAILLE_HEADER_REC],1 ;(viseur bonus ?)

;mov byte ptr fs:[1966080+TAILLE_HEADER_REC],1 ;(viseur bonus ?)
mov replayer_saver,4 ; (taille octet suite a BONUS_REC)

mov eax,dword ptr fs:[esi+TAILLE_HEADER_REC-13]
BIGENDIANPATCH eax
mov replayer_saver2,eax

mov action_replay,2 ;play
mov eax,dword ptr fs:[esi+TAILLE_HEADER_REC-17] ;nombre de dyna
BIGENDIANPATCH eax
mov [nombre_de_dyna],eax
mov replayer_saver3, eax
mov byte ptr [ordre],''
POPALL
ret
retyeyutyuutyyutyutyuioodfgdfgdfggdf:
;****************************************************



cmp [total_t+8*7],1
jne erertertertpert

;cmp byte ptr [clavier+28],1
;jne erertertertpert

;cmp nombre_de_dyna,1
;ja startGame

cmp team3_sauve,1
jne pascolormode
cmp nombre_de_dyna,2
ja startGame
bruit2 14 40   ;fail because not enough players in colormode
jmp erertertertpert
pascolormode:

cmp [nombre_de_dyna],1
ja startGame

cmp nombre_de_dyna,0
jne nozerodyna
bruit2 14 40   ;fail because not enough players in colormode
jmp erertertertpert
nozerodyna:

cmp nb_ai_bombermen,1
jne donenottoaddacpuifonlyonecpuregistered
bruit2 14 40   ;fail because not enough players in colormode
jmp erertertertpert
donenottoaddacpuifonlyonecpuregistered:

call start_cpu_player

startGame:

bruit2 15 40

;cmp demande_partie_slave2,0
;je jkrltjhetjhejhjhtejhhjthjehjehjerjherlhjetlhljter2
;cmp demande_partie_slave,1
;je jkrltjhetjhejhjhtejhhjthjehjehjerjherlhjetlhljter
;jkrltjhetjhejhjhtejhhjthjehjehjerjherlhjetlhljter2:




;jkrltjhetjhejhjhtejhhjthjehjehjerjherlhjetlhljter:

;mov demande_partie_slave,0
;mov [on_a_bien_fait_une_partie],1
mov byte ptr [ordre],''
erertertertpert:


;cmp byte ptr [clavier+2],1
;jne erertertertperterre
;mov [viseur_liste_terrain],0
;erertertertperterre:
;cmp byte ptr [clavier+3],1
;jne erertertertperterrert
;mov [viseur_liste_terrain],1
;erertertertperterrert:
;cmp byte ptr [clavier+4],1
;jne erertertertperterrert4t
;mov [viseur_liste_terrain],2
;erertertertperterrert4t:
;cmp byte ptr [clavier+5],1
;jne erertertertperterrert4t54
;mov [viseur_liste_terrain],3
;erertertertperterrert4t54:
;cmp byte ptr [clavier+6],1
;jne erertertertperterrert4t54r
;mov [viseur_liste_terrain],4
;erertertertperterrert4t54r:
;cmp byte ptr [clavier+7],1
;jne erertertertperterrert4t54rt5
;mov [viseur_liste_terrain],5
;erertertertperterrert4t54rt5:
;cmp byte ptr [clavier+8],1
;jne erertertertperterrert4t54rt5y
;mov [viseur_liste_terrain],6
;erertertertperterrert4t54rt5y:
;cmp byte ptr [clavier+9],1
;jne erertertertperterrert4t54rt5yd
;mov [viseur_liste_terrain],7
;erertertertperterrert4t54rt5yd:


;cmp byte ptr [clavier+5],1
;jne erertertertperterrert4t3
;mov [viseur_liste_terrain],3
;erertertertperterrert4t3:

;----------------------------------------------------------------

;--------- récupere touches pour personnes déja inscrites...

push ds
pop es

mov ebp,[nombre_de_dyna]
or  ebp,ebp
jz yen_a_pas
xor ebx,ebx
xor edx,edx

ooooooooh:

cmp [name_joueur+ebx],4 ;finito
je ms_dos

;---- copie le nom du joueur

mov esi,offset nick_t
add esi,[control_joueur+ebx]
lodsd
mov dword ptr [texte1+6*1+1+32*0+edx],eax
mov dword ptr [texte1+6*1+1+32*1+edx],eax
mov dword ptr [texte1+6*1+1+32*2+edx],eax
mov dword ptr [texte1+6*1+1+32*3+edx],eax

;---- affiche le curseur.
cmp [name_joueur+ebx],1
jb  retrterteoooshow
cmp [name_joueur+ebx],3
ja  retrterteoooshow
push edx
mov dword ptr [texte1+6*2+32*0+edx],'    '
mov dword ptr [texte1+6*2+32*1+edx],'    '
mov dword ptr [texte1+6*2+32*2+edx],'    '
mov dword ptr [texte1+6*2+32*3+edx],'    '

add edx,[name_joueur+ebx]
mov byte ptr [texte1+6*2+32*0+edx],'-'
mov byte ptr [texte1+6*2+32*1+edx],'-'
mov byte ptr [texte1+6*2+32*2+edx],'-'
mov byte ptr [texte1+6*2+32*3+edx],'-'
pop edx
retrterteoooshow:
;-------------------
;regarde si on a pressé...
dec [temps_joueur+ebx]
cmp [temps_joueur+ebx],0
jne ertterrtytyrrtyrtyrtyrtytuoooooooooo

;les fleches... changement d'un caratere...
mov esi,offset total_t
add esi,[control_joueur+ebx]
cmp byte ptr [esi+3],0
je pas_flechedu
;mov temps_avant_demo,ttp
push esi
mov esi,offset nick_t
add esi,[control_joueur+ebx]
add esi,[name_joueur+ebx]
dec byte ptr [esi-1]
cmp byte ptr [esi-1],'a'-1
jne ertrteertterrterterte
mov byte ptr [esi-1],'z'+13 ;,'a'
ertrteertterrterterte:
pop esi
mov [temps_joueur+ebx],temps_re_menu
jmp finito_touches
pas_flechedu:

;les fleches... changement d'un caratere...
mov esi,offset total_t
add esi,[control_joueur+ebx]
cmp byte ptr [esi+0],0
je upas_flechedu
;mov temps_avant_demo,ttp
push esi
mov esi,offset nick_t
add esi,[control_joueur+ebx]
add esi,[name_joueur+ebx]
inc byte ptr [esi-1]
cmp byte ptr [esi-1],'z'+14
jne uertrteertterrterterte
mov byte ptr [esi-1],'a' ;'z'+13
uertrteertterrterterte:
pop esi
mov [temps_joueur+ebx],temps_re_menu
jmp finito_touches
upas_flechedu:



;les fleches...

mov esi,offset total_t
add esi,[control_joueur+ebx]
cmp byte ptr [esi+1],0
je pas_fleched
;mov temps_avant_demo,ttp
inc [name_joueur+ebx]
cmp [name_joueur+ebx],4
jne pertertras_flechedertertertret
mov [name_joueur+ebx],3
jmp ooooiio
pertertras_flechedertertertret:
bruit 5,40,BLOW_WHAT2
ooooiio:
mov [temps_joueur+ebx],temps_re_menu
jmp finito_touches
pas_fleched:

cmp byte ptr [esi+2],0
je pas_flechedm
;mov temps_avant_demo,ttp
dec [name_joueur+ebx]
cmp [name_joueur+ebx],0
jne pertertras_flechedertertertretm
mov [name_joueur+ebx],1
jmp ootoi
pertertras_flechedertertertretm:
bruit 5,40,BLOW_WHAT2
ootoi:
mov [temps_joueur+ebx],temps_re_menu
jmp finito_touches
pas_flechedm:

;--- sort...
;cmp byte ptr [esi+4],0
;je pas_flechedmy
actionButtonPushed pas_flechedmy

;mov temps_avant_demo,ttp
;---- que si sur le 3eme caractere. sinon decalle...

cmp [name_joueur+ebx],3
je pertertras_flechedertertertrety

bruit 5,40,BLOW_WHAT2

inc [name_joueur+ebx]
mov [temps_joueur+ebx],temps_re_menu
jmp finito_touches
pertertras_flechedertertertrety:
;;====================--------- cas particulier de gruge !!! rmc:
;PUSHALL
;mov esi,offset nick_t
;add esi,[control_joueur+ebx]
;;------ pourle retour ici dans longtemps --
;cmp byte ptr [esi+4],''      ;pour ke ca soit retire ensuite...
;jne etreyytyyyuuuuuuuuuu
;mov byte ptr [esi+4],' '
;etreyytyyyuuuuuuuuuu:
;;-------------
;;--- pour la 2eme fois ou on passe la !! (juste apres :))
;cmp byte ptr [esi+4],'t'      ;pour ke ca soit retire ensuite...
;jne treyytyyyuuuuuuuuuu
;mov byte ptr [esi+4],''
;treyytyyyuuuuuuuuuu:
;;-----------------------------
;mov eax,dword ptr [nomdetriche]
;cmp dword ptr [esi],eax
;jne iiuiuiuoooooooooooooooooo
;mov eax,dword ptr [nomdetriche2]
;mov dword ptr [esi],eax
;mov byte ptr [esi+4],'t'
;POPALL
;mov [temps_joueur+ebx],temps_re_menu
;jmp finito_touches
;iiuiuiuoooooooooooooooooo:
;POPALL
;======================----------------------------------------------------------

bruit 3,40,BLOW_WHAT2

;on est sur le 3eme caracte !! finito !!

mov [name_joueur+ebx],4

mov eax,[control_joueur+ebx]

shr eax,6 ;/64
inc eax
add al,'0'

mov esi,offset nick_t
add esi,[control_joueur+ebx]
push eax
mov eax,[esi]

mov esi,offset message2
mov [esi],eax
mov [esi+32],eax
mov last_name,eax
pop eax
mov byte ptr [esi+16+32*2],al
mov byte ptr [esi+16+32*3],al
mov edi,offset texte1
add edi,edx
mov ecx,32
rep movsd


;dans ebx... nomé du mec... cas particulier...
;cmp ebx,'rmd '

PUSHALL
xor ebx,ebx
xor ebp,ebp

enojjojortyrtyrtytyr:
mov eax,dword ptr [love_si+ebx]
cmp last_name,eax
jne nonon_
mov esi,[offset_si+ebp]
mov edi,offset texte1
add edi,edx
mov ecx,[offset_si+ebp+4]
rep movsd
mov eax,'FFFF' ;pour sortir
nonon_:
add ebp,8
add ebx,4
cmp eax,'FFFF'
jne enojjojortyrtyrtytyr
POPALL

jmp finito_touches
pas_flechedmy:

mov [temps_joueur+ebx],1
finito_touches:

ertterrtytyrrtyrtyrtyrtytuoooooooooo:
;-------------------

ms_dos:
add ebx,4
add edx,32*4
dec ebp
jnz ooooooooh
;name_joueur     dd 8 dup (?) ;pour dans le menu...

;name_joueur     dd 8 dup (?) ;pour dans le menu...
;0: pas encore inscrit.
;1: récupere la premiere lettre
;2: récupere la premiere lettre
;3: récupere la troisieme lettre
;4: finis... attend de jouer
;temps_joueur   dd 8 dup (temps_re_menu) ;temps d'attente avant validation
                                        ;d'une nouvelle frappe de touche.
                                        ;dans menu...
yen_a_pas:
;--------------------------------------------------------

mov ebp,[nombre_de_dyna]
cmp ebp,8
je finito_trop_de_dyna

shl ebp,2 ;nombre de joueurs x4

mov esi,offset differents_offset_possible ;dans la table des offset du tas
                                          ; de touches.
eetterrterterterteertterertert:

mov ebx,[esi]
cmp ebx,666 ;fin...
je ok_on_en_a_trouve_un

;cmp byte ptr [total_t+ebx+4],1
;jne touche_non_appuyee
actionButtonPushed2 touche_non_appuyee

;---regarde si ce EBX n'est pas deja dans le control_joeur...
;   cmp byte ptr [esi+ebx+4],1

;jmp plusieur ;renegade ***********************

push ebp
or ebp,ebp
jz ca_roule_mon_coco
tretrrtrtrtrtrttr:
sub ebp,4
cmp [control_joueur+ebp],eBx
jne reetretrert
;et non on l'avait deja pris...
pop ebp
jmp touche_non_appuyee
reetretrert:
or ebp,ebp
jnz tretrrtrtrtrtrttr
ca_roule_mon_coco:
pop ebp
;--
plusieur:

mov dword ptr [control_joueur+ebp],ebx
inc [nombre_de_dyna]
push ds
pop es

;--- sonne

;a: sample, b:note

bruit 3,40,BLOW_WHAT2

; on va marquer le numero de l'ordy connecté...

;mov eax,esi
;sub eax,offset differents_offset_possible
;shr eax,4
;inc eax
;add al,'0'
;mov ah,byte ptr [nombre_de_dyna]
;add ah,'0'

mov esi,offset message3 ;2

;mov byte ptr [esi+5],ah
;mov byte ptr [esi+5+32],ah
;mov byte ptr [esi+16+32*2],al
;mov byte ptr [esi+16+32*3],al

mov [name_joueur+ebp],1
mov edi,offset texte1
shl ebp,5 ;*32 (deja x4)
add edi,ebp
mov ecx,32
rep movsd
jmp ok_on_en_a_trouve_un

touche_non_appuyee:
add esi,4
jmp eetterrterterterteertterertert

finito_trop_de_dyna:
ok_on_en_a_trouve_un:
;----

POPALL
ret
menu_intelligence endp
controle_joueur_fleche proc near ;touches fleches
PUSHALL
;75,77,80,72
mov ebx,[edi]
cmp byte ptr [clavier+ebx],1
jne erertertert
mov byte ptr [esi+2],1
erertertert:

mov ebx,[edi+4]
cmp byte ptr [clavier+ebx],1
jne erertertert2
mov byte  ptr  [esi+1],1
erertertert2:

mov ebx,[edi+8]
cmp byte ptr [clavier+ebx],1
jne erertertert3
mov byte  ptr  [esi],1
erertertert3:

mov ebx,[edi+12]
cmp byte ptr [clavier+ebx],1
jne erertertert4
mov byte  ptr  [esi+03],1
erertertert4:

mov ebx,[edi+16]
cmp byte ptr [clavier+ebx],1
jne erertertert45
mov  byte ptr  [esi+04],1
erertertert45:

mov ebx,[edi+20]
cmp byte ptr [clavier+ebx],1
jne ererterter45
mov byte ptr  [esi+05],1
ererterter45:

mov ebx,[edi+24]
cmp byte ptr [clavier+ebx],1
jne ererterter455
mov byte ptr  [esi+06],1
ererterter455:


;offset 0         =1 si la fleche bas est pressé/               j1
;       1         =1 si la fleche droite est pressé             j1
;       2         =1 si la fleche gauche est pressé             j1
;       3         =1 si la fleche haut est pressé2              j1
;       4         =1 bouton 1                                   j1
;       5         =1 bouton 2                                   j1


POPALL
ret
endp



gestion_jeu proc near ;uniquement appelé par le master.
PUSHALL

;;cas particulier: terrain6 plus apres lapocalypse, pas de bonus
;decompte le tempos pendant lekel ya pas de bonus
;---
cmp special_nivo_6,0
je iophrehuiophuioeterterrte
dec special_nivo_6
iophrehuiophuioeterterrte:
;---

;************************************* refuse une pause tout de suite !!!

cmp action_replay,0
jne ytnononono_onest_en_recordplaye
cmp twice,1
jne ytnononono_onest_en_recordplaye
cmp nombre_de_vbl_avant_le_droit_de_poser_bombe,(nombre_de_vbl_avant_le_droit_de_poser_bombe2-10)/2
ja erteetetretrerterterter
jmp klhlkjljkjkljlkjkljkljklkljkljkljkljklj
ytnononono_onest_en_recordplaye:
cmp nombre_de_vbl_avant_le_droit_de_poser_bombe,nombre_de_vbl_avant_le_droit_de_poser_bombe2-10
ja erteetetretrerterterter
klhlkjljkjkljlkjkljkljklkljkljkljkljklj:

;mov byte ptr [esi],0
;mov [lapipipino3+ebp],duree_saut
;mov [lapipipino2+ebp],1
;mov [lapipipino6+ebp],1
;transformation homme -> lapin doit se faire uniqment ici. car ca serrait
;un demi-lapin dans le process sinon. clair ?
PUSHALL
xor ebp,ebp
ertyrtyutyutyutyuioooppp:
cmp [lapipipino6+ebp],1
jne ertytyuyututyuyyuiyui
mov [lapipipino6+ebp],0
mov [lapipipino+ebp],1
mov [lapipipino3+ebp],duree_saut
mov [lapipipino2+ebp],1
ertytyuyututyuyyuiyui:

cmp [lapipipino6+ebp],2
jne ertytyuyututyuyyuiyuir
mov [lapipipino6+ebp],0
mov [lapipipino+ebp],0
mov [lapipipino3+ebp],0
mov [lapipipino2+ebp],0
ertytyuyututyuyyuiyuir:


add ebp,4
cmp ebp,4*8
jne ertyrtyutyutyutyuioooppp
POPALL
;
call gestion_pause
cmp pauseur2,0
je erteetetretrerterterter
call donnee_to_donnee4 ;passe de donne a donnee4
POPALL
ret
erteetetretrerterterter:
;******************

call transmet_central  ; transmet au CENTRAL les infos k'on vient de pomper.

SOUND_FAC BLOW_WHAT2

call dec_temps
call gestion_bdraw

cmp action_replay,0
jne nononono_onest_en_recordplaye
cmp twice,1
jne nononono_onest_en_recordplaye
cmp twice2,1
je nononono_onest_en_recordplaye
call dec_temps
call gestion_bdraw
nononono_onest_en_recordplaye:

call fabrique_monstro_truc
call gestion_blanchiment

call contamination ;contamination de dyna ?.

mov ecx,[nombre_de_dyna]
xor ebp,ebp ;--- bp: joeur en ce moment *4
brouter:
push ecx

mov esi,[liste_couleur+ebp] ;offset blanc ;esi: couleur du joeur...

call gestion_lapin

;------ patineur ----------------------------
cmp [patineur+ebp],0
je OooooOooooooOooooooooooOooooooooooOoooooo
call gestion_lapin
OooooOooooooOooooooooooOooooooooooOoooooo:
;--- maladie de la speed ---
cmp word ptr [maladie+ebp],01B
jne OooooOooooooOooooooooooOooooooooooOooooooe
call gestion_lapin
OooooOooooooOooooooooooOooooooooooOooooooe:

cmp action_replay,0
jne tnononono_onest_en_recordplaye
cmp twice,1
jne tnononono_onest_en_recordplaye
call gestion_lapin
tnononono_onest_en_recordplaye:



;-malade ???
cmp word ptr [maladie+ebp],0 ;malade ??? (en general)
je ertterterrterterte
cmp [lapipipino+ebp],0 ;lapin ?
jne ertterterrterterte ;si oui, on doit pas gerer le changement de couleur
                       ;ici...

mov ax, word ptr [maladie+ebp+2] 
and eax, 1023
cmp [blinking+eax], 0

jnz ertterterrterterte
mov esi,[liste_couleur_malade+ebp]
ertterterrterterte:
;-----

call anim_un_joeur

cmp [vie+ebp],1
jne erertert
Call touches_action
call la_mort ;regarde si elle a frappée. OU si on a mangé un BONUS...
erertert:

add ebp,4
pop ecx
dec ecx
jnz brouter
;dans ebp: viseur sur numéro du joeur. enfin du premier monstre
;------ il reste les méchants é gérer ---
cmp [nombre_de_monstres],0
je y_en_a_pas

mov ecx,[nombre_de_monstres]
;--- bp: joeur en ce moment *4
tbrouter:
push ecx

cmp [vie+ebp],1
jne  next_monstre

cmp [blocage+ebp],0
jne ertreteretterter
call intelligence_monstre
ertreteretterter:
call la_mort_monstre ;regarde si elle a frappée.
next_monstre:
mov esi,[liste_couleur+ebp] ;offset blanc ;esi: couleur du joeur...
PUSHALL
call anim_un_joeur
POPALL

cmp [vie+ebp],1
jne next_monstre2
cmp [blocage+ebp],0
jne next_monstre2

;---- si le monstre est monté sur la flamme.. on lui dit pas bonne idée..
jmp anti_bomb_monstre
nonononononononon: ;retours anti_bomb pas sur une bombe...
;;si pas reussit a bouger. remet anciennes touches ...
cmp [avance+ebp],1 ;=0 si PAS reussit a bouger
je retererttZERer     ;=1 si reussit a bouger...
mov eax,[touches_save+ebp]
or  eax,128 ;fige...
mov [touches+ebp],eax
ouiuouiouiuoi: ;retours anti_bomb aletre rouge changement de CAP....
mov esi,[liste_couleur+ebp] ;offset blanc ;esi: couleur du joeur...
PUSHALL
call anim_un_joeur
POPALL
retererttZERer:
next_monstre2:

add ebp,4
pop ecx
dec ecx
jnz tbrouter
y_en_a_pas:
;------------------------------------------

call minuteur ;pour les bombes... fauit le tic tic tic :)

call monsieur_bombe ;crée l'affichage les bombes
call monsieur_brik
call calc_ombres
call phase ;draw game ??? fin machin ???

cmp byte ptr [ordre2],'' ;on ne fait pas ca si on a quitté le jeu...
jne reertertertertert
call donnee_to_donnee4 ;passe de donne a donnee4
reertertertertert:

POPALL
ret
gestion_lapin:
  ;====== SPECIAL LE LASCAR EST UN MOTHAFUCKAAAA DE LAPINA (3lit3)
  cmp [lapipipino+ebp],1
  jne ertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuioe
  ;c'est un lapin

mov esi,[lapin_mania1+ebp] ; pointeur sur la bloc de position
                             ; du lapin normal
  ;c'est un lapin qui fait un saut vertical de lapin



;  cmp [lapipipino2+ebp],2 ;saut direction
;  je ertrterterteertzerzererzzer

  cmp [lapipipino2+ebp],0  ;lapin ki fait rien
  je ertrterterteert

;  cmp [lapipipino2+ebp],1 ;saut vertical ou mort du lapin
;  jne ertrterterteert ;lapin ki fait rien
  ertrterterteertzerzererzzer:

;..................... LAPIN QUI SAUTE ......................................

  mov [lapipipino4+ebp],0 ;hauteur du lapin (Y)
  mov [lapipipino5+ebp],0 ;hauteur du lapin (Y)

  ;decrementation du compteur saut
;  dec [lapipipino3+ebp]
;  jz ohohohohohohh
  dec [lapipipino3+ebp]
  jnz erterterterterertrterterteert
;ohohohohohohh:

;--- cas particulier lapin mort
  cmp [lapipipino2+ebp],3 ;mort
  jne rttyuooooooo
  mov [lapipipino6+ebp],2
  jmp ertrterterteert ;c pu un lapin ki saute (ou lapin mort..)
  rttyuooooooo:
;-------------
  mov [lapipipino2+ebp],0 ;arrete le saut
  jmp ertrterterteert ;c pu un lapin ki saute (ou lapin mort..)
  erterterterterertrterterteert:

  ;******************* lapin ki saute phase 1 ***********************
  cmp [lapipipino3+ebp],duree_saut-15 ;compteur dans le saut du lapin
  ja trtyrtyrtyrtyrtyrty
  cmp [lapipipino3+ebp],15            ;compteur dans le saut du lapin
  jb trtyrtyrtyrtyrtyrty

  cmp [lapipipino2+ebp],3    ;mort (cas particulier, esi, tjs le meme)
  je ertertertrterterteertzerzererzzerrtyrtrtyyrtrty
  mov esi,[lapin_mania3+ebp] ; milieu de saut
ertertertrterterteertzerzererzzerrtyrtrtyyrtrty:
  push eax ebx
  mov ebx,[lapipipino3+ebp] ;compteur dans le saut du lapin
  sub ebx,15
  add ebx,ebx
  xor eax,eax
  mov ax,[saut_de_lapin+ebx]
  cmp [lapipipino2+ebp],1 ;saut vertical
  jne ertrterterteertererer
  mov ax,[saut_de_lapin2+ebx]
  ertrterterteertererer:
  mov [lapipipino5+ebp],eax ;hauteur du lapin x1
  EAX_X_320
  mov [lapipipino4+ebp],eax ;hauteur du lapin x320
  pop ebx eax

;********************************** lapin qui saute directionnellement
  ;---- deplace le lapin ---
  cmp [lapipipino3+ebp],duree_saut-15 ;compteur dans le saut du lapin
  je ertrterterteert
  cmp [lapipipino2+ebp],2 ;que lapin sautant dans une direction
  jne  ertrterterteert

  ;compteur a partir dukel on ne fait plus avancer le lapin 17 normallement
push eax
  mov eax,[lapipipino7+ebp]
  cmp [lapipipino3+ebp],eax
  jnb ertrterterteert_oooo
pop eax
jmp ertrterterteert
ertrterterteert_oooo:
pop eax

  push eax ebx
  mov ebx,ebp
  shr ebx,1
  ;mov ah,02h ;SUPER_SIGNE2 DB 0
  ;mov dl,13
  ;int 21h

;8: gauche
  mov eax,[touches+ebp]
  and eax,127
  cmp eax,8
  jne trrtertyrtytyrtyrrty
;donnee       dw 8 dup (?) ;x du dynablaster
;             dw 8 dup (?) ;y du dynablaster
  inc [donnee+ebx]
  trrtertyrtytyrtyrrty:
  cmp eax,16
  jne trrtertyrtytyrtyrrtyR
  dec [donnee+ebx]
  trrtertyrtytyrtyrrtyR:
  cmp eax,00
  jne trrtertyrtytyrtyrrtyy
;donnee       dw 8 dup (?) ;x du dynablaster
;             dw 8 dup (?) ;y du dynablaster
  inc [donnee+8*2+ebx]
  trrtertyrtytyrtyrrtyy:
  cmp eax,24
  jne trrtertyrtytyrtyrrtyRy
  dec [donnee+8*2+ebx]
  trrtertyrtytyrtyrrtyRy:
  pop ebx eax

PUSHALL
push ebp
xy_to_offset
pop ebp
lea esi,[truc+eax]
mov [last_bomb+ebp],esi
POPALL
  jmp ertrterterteert
  ;-------------------------
  trtyrtyrtyrtyrtyrty:

;******************* LAPIN FASE SE COURBE (?) *

  cmp [lapipipino3+ebp],duree_saut-7
  ja trtyrtyrtyrtyrtyrtyu
  cmp [lapipipino3+ebp],7
  jb trtyrtyrtyrtyrtyrtyu
  mov esi,[lapin_mania4+ebp] ; preske normal
  jmp ertrterterteert
  trtyrtyrtyrtyrtyrtyu:
  mov esi,[lapin_mania2+ebp] ; se courbe
  ertrterterteert:

;----- lapin mort !!! ----
  cmp [lapipipino2+ebp],3    ;mort (cas particulier, esi, tjs le meme)
  jne  kertrterterteert

  push eax ebx
  mov ebx,[lapipipino3+ebp] ;compteur dans le saut du lapin
  add ebx,ebx
  xor eax,eax
  mov ax,[mort_de_lapin+ebx]
  mov [lapipipino5+ebp],eax ;hauteur du lapin x1
  EAX_X_320
  mov [lapipipino4+ebp],eax ;hauteur du lapin x320
  mov esi,[lapin_mania5+ebp] ; pointeur sur la bloc de position
                             ; du lapin mort
  pop ebx eax
  kertrterterteert:
;---------------

  ertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuioe:
  ;====================================================

ret
gestion_pause:


;*******************************
;gestion, sprite

;pas de pause en action replay

cmp pauseur2,0
je pas_en_pauseer
test dword ptr [changement],0000000001111B
jnz pas_en_pauseer

xor ebx,ebx
mov bl,pauseur2
add ebx,4
cmp [offset_pause+ebx],666
jne ihhihiertteretr
mov ebx,4
ihhihiertteretr:
mov pauseur2,bl

pas_en_pauseer:


;*******************************

cmp pause2,0
je uerertertert
dec pause2
uerertertert:

cmp pause,1 ;touche vient d'etre touchee/relachee ?
jne raison_detat

;;------------- gestion sprite
;xor ebx,ebx
;mov bl,pause
;dec bl
;shl ebx,2
;
;add ebx,4
;cmp [offset_pause+ebx],666
;jne uiyuighguirrtrt
;xor ebx,ebx
;uiyuighguirrtrt:
;inc bl
;mov pause,bl
;;------------------------------

mov pause,0
cmp pause2,0
jne dejapresseyapaslongtemps
mov pause2,15
;pauseur2
;NOT pauseur2
cmp pauseur2,0
jne reeertertterert
mov pauseur2,4
jmp raison_detat
reeertertterert:
mov pauseur2,0
raison_detat:
dejapresseyapaslongtemps:
ret

anti_bomb_monstre:

cmp [invinsible+ebp],0
jne nonononononononon ;si il s'est prit dans la bombe il faut k'il se tretourne.
                     ;ou alors il resiste donc on s'en fou.
PUSHALL
;cmp [avance+ebp],1 ;=0 si PAS reussit a bouger
;je reterertter     ;=1 si reussit a bouger...

push ebp
xy_to_offset
lea esi,[truc2+eax]
pop ebp

cmp byte ptr [esi],5
jb ertterertertertertt
cmp byte ptr [esi],54
jnb ertterertertertertt
mov [avance+ebp],0 ;=0 si PAS reussit a bouger. vaut mieu pas babe..
;+ mouvement inverse...
mov ebx,[touches+ebp]
and ebx,127 ;défige...
mov eax,[anti_bomb+ebx]
mov [touches+ebp],eax
POPALL
jmp ouiuouiouiuoi
ertterertertertertt:
POPALL
jmp nonononononononon ;retours anti_bomb
intelligence_monstre:

mov esi,[infojoueur+ebp]
mov ecx,dword ptr [esi+12]
cmp ecx,1
jne pas_1i
test dword ptr [changement],00000000111B
jnz non_bouge_pasttryrtytyr
jmp ok_il_bougert
pas_1i:
cmp ecx,2
jne ok_il_bougert
test dword ptr [changement],00000000011B
jnz non_bouge_pasttryrtytyr
jmp ok_il_bougert
non_bouge_pasttryrtytyr:
ret
ok_il_bougert:
;1,2,3 (normal),4:double...

;--- intelligence ----

mov eax,[changement]
add eax,[avance2+ebp]          ;hazard
add eax,[viseur_change_in+ebp] ;hazard total...
;add eax,[maladie+ebp] ;hazard..
;add eax,dword ptr [donnee+ebp] ;hazard..
add eax,ebp ;nouveau hazard.. violent
and eax,01111111B
jnz alllagrishna

cmp [avance2+ebp],3 ;compte a rebourd avant nouvelle action...
jb arrete__
mov [avance2+ebp],3 ;compte a rebourd avant nouvelle action...
jmp arrete__
alllagrishna:

cmp [avance+ebp],1 ;=0 si PAS reussit a bouger
je reterertter     ;=1 si reussit a bouger...

;si reussit continue...
;pas reussit

arrete__:

dec [avance2+ebp] ;compte a rebourd avant nouvelle action...
jnz mendier
hier2:

mov [avance2+ebp],15

PUSHALL
mov ebx,[viseur_change_in+ebp]
mov eax,[changeiny+ebx]
mov [touches+ebp],eax
add [viseur_change_in+ebp],4
cmp [viseur_change_in+ebp],16*4
jne retkortykokoptrkopkop
mov [viseur_change_in+ebp],0
retkortykokoptrkopkop:
POPALL
                      ;0= face        bas.
                      ;8= droite      droite
                      ;16= gauche     gauche
                      ;24= haut       haut

jmp mendier
reterertter:
mov eax,[touches+ebp] ;sauvegarde du dernier success d'un monstre...
mov [touches_save+ebp],eax
;------------------
mendier:
ret

donnee_to_donnee4:
PUSHALL
;POPALL
;push ecx


xor ecx,ecx ;0,nb_unite_donnee4,...
xor ebx,ebx ;0,2,4,
xor ebp,ebp ;0,4,8,12,...
;***
hooooooop:
;----- calcule dans edi le Y en le multipliant par 320

;;EAX_X_320
;;mov [vise_de_ca_haut2+ebp],eax

xor eax,eax
mov ax,word ptr [donnee+nb_dyna*2+ebx] ;y
push eax
shl   eax,6 ; x 64
mov   edi,eax
pop eax
shl   eax,8 ; x 256
add   edi,eax
;-------------- rajoute le X
xor eax,eax
mov ax,word ptr [donnee+ebx]
add edi,eax
;---------------

  mov [vise_de_ca_haut+ebp],0
  mov [vise_de_ca_haut2+ebp],0
  ;====== SPECIAL LE LASCAR EST UN MOTHAFUCKAAAA DE LAPINA (3lit3)
  cmp [lapipipino+ebp],1
  jne ertrtyyuttyutyurtyutyutyuyutyut
  ;=== cas particulier: trop haut./ deborderait de l'ecran
  push eax
  xor eax,eax
  mov ax,word ptr [donnee+nb_dyna*2+ebx] ;y
  mov edx,[lapipipino5+ebp]
  add edx,13
  cmp ax,dx
  ja erertzertertertertertert

;combien_faut_baisser dd 320*14,320*13,320*12,320*11,320*10,320*9,320*8
;                    dd 320*7,320*6,320*5,320*4,320*3,320*2,320*1
;combien_faut_baisser2 dd 14,13,12,11,10,9,8
;                     dd 7,6,5,4,3,2,1

;push ebx

;push eax
neg eax
add eax,edx
inc eax
mov [vise_de_ca_haut2+ebp],eax
;pop eax

;mov [vise_de_ca_haut2+ebp],eax

;xor ebx,ebx
;shl ax,2
;mov bx,ax

;mov eax,[combien_faut_baisser2+ebx]
;mov [vise_de_ca_haut2+ebp],eax
;mov eax,[combien_faut_baisser+ebx]
EAX_X_320
;mov [vise_de_ca_haut2+ebp],eax
;pop ebx
  add edi,eax ;320*14
  mov [vise_de_ca_haut+ebp],eax ;320*14
  erertzertertertertertert:
  pop eax
  ;=== attention au adder, faut pas kon le mette trop haut ================
  add edi,-14*320-4
  sub edi,[lapipipino4+ebp] ;saut du lapin (y)
  or edi,edi                                   ;!
  jns rterteerertertterteryuyyuuuuu            ;!
  add edi,[lapipipino4+ebp] ;saut du lapin (y) ;!
                                               ;!
  ;bon on bidouille !!
  push eax
  mov eax,[lapipipino4+ebp]
;  add [lapin_mania+ebp],eax ;pointeur sur la source memoire
;  add [vise_de_ca_haut+ebp],eax
  pop eax
  rterteerertertterteryuyyuuuuu:

  jmp tryrtyyrttyutyuyuttyutyutyutyutyutyutyu
  ertrtyyuttyutyurtyutyutyuyutyut: ;pas un lapin
  add edi,dword ptr [donnee+112+ebp] ;adder y.. (car girl plus gaut!!!)
  tryrtyyrttyutyuyuttyutyutyutyutyutyutyu:
  ;============
mov word ptr [donnee4+ecx+4],di
;---------------

;----- OFFSET EN MEMOIRE -------------
xor eax,eax
mov ax,word ptr [donnee+nb_dyna*4+ebx]

cmp ax,666 ;mort... et on affiche plus...
je reertertertrte
  ;====== SPECIAL LE LASCAR EST UN MOTHAFUCKAAAA DE LAPINA (3lit3)
  cmp [lapipipino+ebp],1
  jne ertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuio
  add eax,[vise_de_ca_haut+ebp] ;decalleur spoecial y

;--- glignotement des lapins malades ---
cmp word ptr [maladie+ebp],0 ;malade ??? (en general)
je ertterterrtertertertt

mov dx, word ptr [maladie+ebp+2]
and edx, 1023
cmp [blinking+edx], 0
jnz ertterterrtertertertt

  add eax,[lapin_mania_malade+ebp] ;pointeur sur la source memoire
  jmp reertertertrte
ertterterrtertertertt:
;------------------------------------------
  add eax,[lapin_mania+ebp] ;pointeur sur la source memoire
  jmp reertertertrte
  ertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuio:
  ;====================================================
add eax,dword ptr [donnee+8*2*3+ebp] ;ou en mémoire!!!
reertertertrte:
mov dword ptr [donnee4+ecx],eax ;source... 666 indique: ne rien afficher

;---
mov ax,word ptr [donnee+8*5*2+ebx]
mov byte ptr [donnee4+6+ecx],al ;nombre de lignes...

mov ax,word ptr [donnee+8*6*2+ebx]
mov byte ptr [donnee4+7+ecx],al ;nombre de colonnes....
;---

  ;====== SPECIAL LE LASCAR EST UN MOTHAFUCKAAAA DE LAPINA (3lit3)
  cmp [lapipipino+ebp],1
  jne rertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuio
  push ax
  mov ax,37
  sub ax,word ptr [vise_de_ca_haut2+ebp]
  mov byte ptr [donnee4+6+ecx],al ;nombre de lignes...
  pop ax
  mov byte ptr [donnee4+7+ecx],32 ;nombre de colonnes....
  rertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuio:
  ;====================================================


;dw 23,23,23,23,25,25,25,25 ;nombre de lignes pour un dyna...
;mov si,word ptr [donnee+nb_dyna*2*2+ebx]
;xor ecx,ecx ;0,7,...
;xor ebx,ebx ;0,2,4,
;xor ebp,ebp ;0,4,8,12,...

mov eax,[clignotement+ebp] ;
and byte ptr [donnee4+8+ecx],011111110B
or byte ptr [donnee4+8+ecx],al

add ecx,nb_unite_donnee4
add ebx,2
add ebp,4
cmp ebp,4*8
jne hooooooop
POPALL
ret
;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
la_mort: ;regarde si elle a frappée. ou si on a mangé un bonus.
PUSHALL
push ebp
xy_to_offset
lea esi,[truc2+eax]
pop ebp


;==== mort par brike sur la gueule ===
cmp [lapipipino+ebp],0 ;lapin ?
je nan_comme_dab
cmp [lapipipino2+ebp],0 ;lapin qui saute pas?
jne nan_laisse_tourner
cmp byte ptr [esi-32*13],11 ;regarde si c a la fin... brique sur la gueulle..
jne nan_laisse_tourner
mov [lapipipino2+ebp],3
mov [lapipipino3+ebp],duree_mort
jmp nan_laisse_tourner
nan_comme_dab:
cmp byte ptr [esi-32*13],11 ;regarde si c a la fin... brique sur la gueulle..
je microsoft
nan_laisse_tourner:
;==================================




cmp byte ptr [esi],5
jb ertterertertertert
cmp byte ptr [esi],54
jnb ertterertertertert

;invinsible    dd 8 dup (?) ;invincibilité. nombre de vbl restant ... décrémentée... 0= none...
;nombre_de_coups dd 8 dup (3) ;avant la mort...

;résistance aux coups/calcul...

resistance ertterertertertert,0

microsoft: ;LA c'est la mort.

;mort d'un dyna par flamme. ou brike sur la gueulle (de dayna)

;-- on lui ote le pouvoir d'explosion retarde ... (ca a deja du etre fait,
; sauf s'il est mort par apocalypse. donc on en remet une couche!)
push ebx ;et sinon ses bombes elles resteraient.
mov ebx,[infojoueur+ebp]
mov dword ptr [ebx+4*4],0
call nike_toutes_ses_bombes
pop ebx
;--------

bruit3 7,35,BLOW_WHAT2
mov [vie+ebp],0

ertterertertertert:

;regarde si on a mangé un bonus

;si on est un lapin en train de sauter on mange pas le bonus
cmp [lapipipino+ebp],0 ;lapin ?
je on_est_pas_un_lapin_on_mange_les_bonus
cmp [lapipipino5+ebp],0 ;en hauteur ?
jne baaaaaaaaaaaaaaaaaaaaaaaah_paas_de_bonus
on_est_pas_un_lapin_on_mange_les_bonus:

bonus_ 54,bombe_max,0
bonus_ 64,bombe_max2,4
bonus_tete 74
bonus_2 84,invinsibilite_bonus,invinsible
bonus_2 94,1,nombre_de_coups
bonus_ 104,1,4*4
bonus_3 114,1,pousseur
bonus_3 124,1,patineur
;horloge
bonus_4 134
bonus_3 144,1,tribombe
bonus_6 154
;oeuf
bonus_5 193
baaaaaaaaaaaaaaaaaaaaaaaah_paas_de_bonus:

;--- regarde si un mechant nous a mangé...
mov eax,[last_bomb+ebp]
cmp [nombre_de_monstres],0
je y_en_a_pas2
mov ebx,[nombre_de_dyna]
shl ebx,2

reetrertetert:
cmp [vie+ebx],1 ;si le mechant il est mort. ben il peut pas nous tuer...
jne pas_tue
cmp eax,[last_bomb+ebx]
jne pas_tue

;résistance aux coups/calcul...
resistance pas_tue,0

;mort d'un dyna
bruit3 7,35,BLOW_WHAT2
mov [vie+ebp],0
pas_tue:
add ebx,4
cmp ebx,32
jne reetrertetert

y_en_a_pas2:

POPALL
ret

la_mort_monstre: ;regarde si elle a frappée.
PUSHALL
push ebp
xy_to_offset
lea esi,[truc2+eax]
pop ebp

cmp byte ptr [esi-32*13],11 ;regarde si c a la fin... brique sur la gueulle..
je microsoft2

cmp byte ptr [esi],5
jb uertterertertertert
cmp byte ptr [esi],54
jnb uertterertertertert

;résistance aux coups/calcul...
resistance uertterertertertert,-1

PUSHALL
sub esi,32*13-1
;inc esi
colle_un_bonus viseur_hazard_bonus2,hazard_bonus2,correspondance_bonus2
POPALL


microsoft2:

;mort d'un monstre courageux.

bruit3 8,35,BLOW_WHAT2
mov [vie+ebp],0
uertterertertertert:
POPALL
ret


;----------------
anim_un_joeur:

cmp [vie+ebp],1
jne rtertterterrterte


                      ;0= face
                      ;8= droite
                      ;16= gauche
                      ;24= haut

  ;cas du lapin ki saute... ne bouge pas comme ca
 ; cmp [lapipipino+ebp],1
 ; jne ertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuioeertertert
 ; cmp [lapipipino2+ebp],1 ;saut vertical
 ; je rtrtyyrtrtytrytyrrty
 ; ertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuioeertertert:


cmp dword ptr [touches+ebp],128 ;on met le bit 7 a 1 si bouge pas.
jb  okbouge_pas
;on a un monstre/dyna ki ne se deplace pas..
;donc on ne le je fait pas gigoter.
; sauf cas particulier: monstre du nivo 7, et nivo micro !!
; ki gigottent tout le temps
and dword ptr [touches+ebp],127
add esi,[touches+ebp] ;variable en central ou ya une valeur pour chaque type
                      ;de deplacement pour un joeur et ceci pour TOUS les
                      ;joeurs...
                      ;les touches.
or  dword ptr [touches+ebp],128 ;remet le bit a 1

;----  cas particulier gigotage
cmp [nombre_de_dyna_x4],ebp ; uniquement si on est pas un humain...
ja non_c_pas_un_monstre2
cmp terrain,7
jne special_monstres_gigoteurs4
;*** c un cas particulier dans le cas particulier.. BIDOUILLE ATTENTION
;il faut ke ca soit des sprites ou les pieds bougent pas !!!
push ebx
xor eax,eax

;mov eax,[changement]
;and eax,0011000B
;shr eax,2

mov ebx,[changement]
;and ebx,0110000B
;shr ebx,3
and ebx,011000B
shr ebx,2

cmp bx,2
jne trhjllhjkrtlhjrhjkltyrlhjkrty
mov ax,-17*2
trhjllhjkrtlhjrhjkltyrlhjkrty:
cmp bx,6
jne trhjllhjkrtlhjrhjkltyrlhjkrty2
mov ax,-17
trhjllhjkrtlhjrhjkltyrlhjkrty2:
add ax,[esi]  ;;ATTENTION JE SUIS HARD CORE LA :))
pop ebx
jmp rtrtyyrtrtytrytyrrtyZERZERZERZER
;****
special_monstres_gigoteurs4:

cmp terrain,3
je special_monstres_gigoteurs
non_c_pas_un_monstre2:
jmp rtrtyyrtrtytrytyrrty
;--------
okbouge_pas:

;------------------------- TOUCHES INVERSEES -------------------------------
cmp [nombre_de_dyna_x4],ebp ; uniquement si on est un humain...
jna ui
cmp word ptr [maladie+ebp],4 ;touches inversée...
jne ui
cmp [touches+ebp],8
jne tyuo
mov [touches+ebp],16
jmp ui
tyuo:
cmp [touches+ebp],16
jne tyuu
mov [touches+ebp],8
jmp ui
tyuu:
cmp [touches+ebp],0
jne tyuo2
mov [touches+ebp],24
jmp ui
tyuo2:
cmp [touches+ebp],24
jne tyuu1
mov [touches+ebp],0
jmp ui
tyuu1:
ui:
;---------------------------------------------------------------------------

;---- lapin ... annule tous les direction si on est en train de sauter ---
;  cmp [lapipipino+ebp],1
;  jne rertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuioeertertert
;  cmp [lapipipino2+ebp],1 ;saut vertical
;  jne rertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuioeertertert
;  or  dword ptr [touches+ebp],128 ;remet le bit a 1
;  rertyrttyrrtytyuutyyuiyuiiyuyuityuioouiioyuuioyyuioeertertert:
;------


add esi,[touches+ebp] ;variable en central ou ya une valeur pour chaque type
                      ;de deplacement pour un joeur et ceci pour TOUS les
                      ;joeurs...
                      ;les touches.

;pour le deplacement...

;-------------- variation du sprite si il bouge... (gauche/droite.. )
special_monstres_gigoteurs:
;cmp [nombre_de_dyna_x4],ebp ; uniquement si on est un humain...
;ja non_c_pas_un_monstre

mov eax,[changement]

;--- c un monstre ??? -----
cmp [nombre_de_dyna_x4],ebp ; uniquement si on est pas un humain...
ja non_c_pas_un_monstre
push ecx ebx
mov ecx,[vitesse_monstre+ebp]
;----
cmp action_replay,0
jne eanononono_onest_en_recordplaye
cmp twice,1
jne eanononono_onest_en_recordplaye
inc ecx
eanononono_onest_en_recordplaye:
;-----

mov ebx,011B
shl ebx,cl
and eax,ebx
dec cl
shr eax,cl
pop ebx ecx
jmp eanononono_onest_en_recordplay
non_c_pas_un_monstre:
;----------------------
and eax,0110000B
shr eax,3
cmp [patineur+ebp],0 ;patineur cour 2 fois plus vite
je tryyyyyyyyyyytyuiouiiuoouiuiooui
mov eax,[changement]
and eax,0011000B
shr eax,2
tryyyyyyyyyyytyuiouiiuoouiuiooui:
;mode twice...--------------------
cmp action_replay,0
jne eanononono_onest_en_recordplay
cmp twice,1
jne eanononono_onest_en_recordplay
;cours 2 fois plus vite
mov eax,[changement]
and eax,0011000B
shr eax,2
eanononono_onest_en_recordplay:
;---------------------------------
add esi,eax
;----------------
rtrtyyrtrtytrytyrrty:

mov ax,[esi]

rtrtyyrtrtytrytyrrtyZERZERZERZER:
push ebp
shr ebp,1
mov [donnee+nb_dyna*4+ebp],ax ;variables en central contenant les infos completes
                          ;nivo affichage pour chaque joueur
                          ;X,Y,offset
pop ebp
;------------ regarde si le sprite se deplace... (X/Y)
cmp [touches+ebp],128 ;variable en central ou ya une valeur pour chaque type
jNB non_bouge_pas


;----- vitesse = normal.. + = + !!!

;infojoueur dd offset j1,offset j2,offset j3,offset j4,offset j5,offset j6,offset j7,offset j8
;premier dd: nombre de bombes que le joeur peut encore mettre.
;deuxieme dd:  puissance de ces bombes... minimum = 1 ...
;troisieme dd: nombre de tous avant que ca pete.
;quatrieme dd: vitesse du joeur... 1:normal...

mov esi,[infojoueur+ebp]
mov ecx,dword ptr [esi+12]

;1,2,3 (normal),4:double...

;-*-*-*-*-*-*-* GESTION vitesse -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
;---- modif..
cmp ecx,1
jne pas_1
test dword ptr [changement],00000000111B
jnz non_bouge_pas
;mov ecx,1
jmp finto_gestion_vitesse
pas_1:
cmp ecx,2
jne pas_2
test dword ptr [changement],00000000011B
jnz non_bouge_pas
mov ecx,1
jmp finto_gestion_vitesse
pas_2:
cmp ecx,3
jne pas_3
mov ecx,1
jmp finto_gestion_vitesse
pas_3:
cmp ecx,4
jne pas_4
mov ecx,2
jmp finto_gestion_vitesse
pas_4:
finto_gestion_vitesse:
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-

;--- mode twice ------------
  cmp action_replay,0
  jne anononono_onest_en_recordplay
cmp twice,1
jne anononono_onest_en_recordplay
inc ecx
anononono_onest_en_recordplay:
;-------------------

;--- patins a roulettes ?
add ecx,[patineur+ebp]

;--- maladie de la speed ---
cmp word ptr [maladie+ebp],01B ;255 ; dd 8 dup (?)
jne ertertrterteterrteert2
add ecx,3
ertertrterteterrteert2:
;----------------------------


;;--- maladie de la lenteur ne marche pas sur le lapin !!!
;cmp [lapipipino+ebp],1
;je ertertrterteterrteert3
;--- maladie de la lenteur --
cmp word ptr [maladie+ebp],02 ;255 ; dd 8 dup (?)
jne ertertrterteterrteert3
test dword ptr [changement],00000000011B
jnz non_bouge_pas
ertertrterteterrteert3:
;----------------------------

;----------------------------
cmp [blocage+ebp],0
je  next_monstre2r2
dec [blocage+ebp]
jmp non_bouge_pas
next_monstre2r2:

;--------------------------------

mov [avance+ebp],1 ;reussit a bouger par défault. (pour monstre)

ertertrterteterrteert:
push ECX


cmp [touches+ebp],8 ;*********** droite
jne ererterertert4
push ebp
shr ebp,1
;------ remet au milieu ----- Y-------------------------------
mov si,16
call remet_milieu_y
jz errteterertertrte3 ;on l'a remis au milieu...
;-------------------------------------------------------------
;dx add x, cx: add y
mov dx,8+1
mov cx,0
call possible_ou_pas
jnz errteterertertrte2 ;impossible
inc [donnee+ebp]
;add ebp,ebp
jmp errteterertertrte3
errteterertertrte2:
;---------------------------
push ebp
add ebp,ebp
mov [avance+ebp],0 ;PAS reussit a bouger apres avoir été replacé. (pour monstre)
pop ebp
errteterertertrte3:
;-----------------------------
pop ebp
ererterertert4:



cmp [touches+ebp],16 ;*********** gauche
jne ererterertert4e
push ebp
shr ebp,1
;------ remet au milieu ----- Y-------------------------------
mov si,-16
call remet_milieu_y
jz errteterertertrte3e
;-------------------------------------------------------------
;dx add x, cx: add y
mov dx,-8
mov cx,0
call possible_ou_pas
jnz errteterertertrte2e ;impossible
dec [donnee+ebp]
;add ebp,ebp
jmp errteterertertrte3e
errteterertertrte2e:
;---------------------------
push ebp
add ebp,ebp
mov [avance+ebp],0 ;PAS reussit a bouger apres avoir été replacé. (pour monstre)
pop ebp
errteterertertrte3e:
;-----------------------------


pop ebp
ererterertert4e:


cmp [touches+ebp],24 ;*********** haut
jne ererterertert4ey
push ebp
shr ebp,1
;------ remet au milieu ----- Y-------------------------------
mov si,-16 ; ;16 ;8
call remet_milieu_x
jz errteterertertrte3ey
;-------------------------------------------------------------
;dx add x, cx: add y
mov dx,0
mov cx,-8
call possible_ou_pas
jnz errteterertertrte2ey ;impossible
dec [donnee+nb_dyna*2+ebp]
;add ebp,ebp
;errteterertertrte2ey:
jmp errteterertertrte3ey
errteterertertrte2ey:
;---------------------------
push ebp
add ebp,ebp
mov [avance+ebp],0 ;PAS reussit a bouger apres avoir été replacé. (pour monstre)
pop ebp
errteterertertrte3ey:
;-----------------------------


pop ebp
ererterertert4ey:

cmp [touches+ebp],0 ;*********** bas
jne ererterertert4eyt
push ebp
shr ebp,1
;------ remet au milieu ----- Y-------------------------------
mov si,16
call remet_milieu_x
jz errteterertertrte3eyt
;-------------------------------------------------------------
;dx add x, cx: add y
mov dx,0
mov cx,8+1
call possible_ou_pas
jnz errteterertertrte2eyt ;impossible
inc [donnee+nb_dyna*2+ebp]
;add ebp,ebp
jmp errteterertertrte3eyt
errteterertertrte2eyt:
;---------------------------
push ebp
add ebp,ebp
mov [avance+ebp],0 ;PAS reussit a bouger apres avoir été replacé. (pour monstre)
pop ebp
errteterertertrte3eyt:
;-----------------------------
pop ebp
ererterertert4eyt:


;----- vitesse/. 1 = normal.. + = + !!!
pop  ECX
dec ecx
jnz ertertrterteterrteert

;
PUSHALL
push ebp
xy_to_offset
pop ebp
lea esi,[truc+eax]
mov [last_bomb+ebp],esi
POPALL

non_bouge_pas:

ret

;dead dyna.
rtertterterrterte:
;add esi,32 ;[vie+ebp]
;add esi,[vie+ebp]
;add esi,0 ;32
add esi,[vie+ebp]
mov ax,[esi+32]
push ebp
shr ebp,1
mov [donnee+nb_dyna*4+ebp],ax
pop ebp

mov eax,[changement]
and eax,000000111B
jnz ertterrteertrterteertrte
cmp dword ptr [vie+ebp],16 ;8*2
je ertterrteertrterteertrte
add dword ptr [vie+ebp],2
ertterrteertrterteertrte:
ret


monsieur_brik:

;--------------- gestion des briques ---------------------------------
;briques dw 3,0,0,0,32,0,64
mov ax,ds
mov es,ax

mov esi,offset truc
mov edi,offset briques+2

xor cx,cx
xor eax,eax

mov bx,8 ;offset dans buffer destionation auquel la case correspond...

mov dx,13
rettertyutyuuityyuityuityuiyuiyuiyui:

push dx

mov dx,19
reertertertertertreerertert:
xor ax,ax
lodsb
or al,al
jz zererrte
cmp al,1
je zererrte
cmp al,66
je zererrte

cmp al,2
je ertrtyrtytyytutyutyuuty
;--- rajout de brique dure pour la fin...
cmp al,11
jne nonononono

xor ax,ax

push ebx
xor ebx,ebx
mov bl,terrain
dec bl
add ebx,ebx
mov ax,[kel_viseur_brike_fin+ebx]
pop ebx

jmp brique_dure_rajoutee
nonononono:
;----------------
;cmp [terrain],2 ;pas ce cas particulier avec la neige...
;jne retterterertertertertertertertertertertertret
test dword ptr [changement],00000000011B
jnz erertrteertert
;j,z rteterterrterterterte
;retterterertertertertertertertertertertertret:
;
;cmp [terrain],4 ;pas ce cas particulier avec la foret
;jne retterterertertertertertertertertertertertret5
;test dword ptr [changement],00000000011B
;jz rteterterrterterterte
;retterterertertertertertertertertertertertret5:
;
;test dword ptr [changement],00000000111B
;jnz erertrteertert
;rteterterrterterterte: ;cas particulier neige  + foret

inc byte ptr [esi-1]

cmp byte ptr [esi-1],11
jne erertrteertert
mov byte ptr [esi-1],0

colle_un_bonus viseur_hazard_bonus,hazard_bonus,correspondance_bonus

erertrteertert:

ertrtyrtytyytutyutyuuty:


sub ax,2
shl ax,4

;------ affiche brique différentes en fonction du terrain...
push ebx
xor ebx,ebx
mov bl,[terrain] ;offset_briques dw 0,0,65+116*320
dec bl
add bx,bx
add ax,word ptr [offset_briques+ebx]
pop ebx
;-----------------

brique_dure_rajoutee:
inc cx
;add ax,320*16*2
stosw
;--------------------
mov ax,bx
stosw
ertteretretrertrte:

zererrte:
add bx,16
rettertertertert:
;*************************************************************************
dec dx
jnz reertertertertertreerertert
pop dx
add esi,13
add bx,320*16-16*19
dec dx
jnz rettertyutyuuityyuityuityuiyuiyuiyui

mov [briques],cx

;truc    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,1,2,1,2,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,1,2,1,2,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0



ret


monsieur_bombe:

;briques dw 3,0,0,0,32,0,64
mov ax,ds
mov es,ax

mov esi,offset truc2
mov edi,offset bombes+2

xor cx,cx
xor eax,eax

mov bx,8 ;offset dans buffer destionation auquel la case correspond...

mov dx,13
trettertyutyuuityyuityuityuiyuiyuiyui:

push dx

mov dx,19
treertertertertertreerertert:
xor ax,ax
lodsb
or al,al
jz tzererrte


cmp al,5
jnb ftttrrtrtyyrtyrtrtyrtytyrrtyrtyrtyrtyrty
;******************************************** bombe qui respire...
test dword ptr [changement],00000001111B
jnz terertrteertert
inc byte ptr [esi-1]
cmp byte ptr [esi-1],5
jne terertrteertert
mov byte ptr [esi-1],1
terertrteertert:
inc cx
dec ax
shl ax,4
add ax,320*16
stosw

;add ax,
;add byte ptr [esi-1],5
;mov

;--- special bombes... adder X/Y
push cx
xor ax,ax
;movsx ax,byte ptr [esi-1+32*13] ;trux_X
mov al,byte ptr [esi-1+32*13]
movsx ax,al  ;byte ptr [esi-1+32*13] ;trux_X^M
add   ax,bx

;movsx cx,byte ptr [esi-1+32*13*2] ;trux_Y
mov cl,byte ptr [esi-1+32*13*2] ;trux_Y^M
movsx cx,cl

push ax
mov ax,cx
shl ax,6 ;*64
shl cx,8 ;*256
add cx,ax
pop ax
add ax,cx
stosw
pop cx
jmp tzererrte
tertteretretrertrte:
;*************************************************
ftttrrtrtyyrtyrtrtyrtytyrrtyrtyrtyrtyrty:

;***************************************************************************

bombe 12
bombe 12+7
bombe 12+7+7
bombe 12+7+7+7
bombe 12+7+7+7+7
bombe 12+7+7+7+7+7
bombe 12+7+7+7+7+7+7

;----- bonus

bonus 64,160
bonus 74,160+320*16
bonus 84,160+320*32
bonus 94,160+320*48
bonus 104,160+320*16*4
bonus 114,160+320*16*5
bonus 124,160+320*16*6
bonus 134,160+320*16*7
bonus 144,160+320*16*8
bonus 154,160+320*16*9
bonus 164,0
;----- bonus qui explose...
oeuf_bonus  193,112+16*320
explo_bonus 194+7,0+172*320

tzererrte:

;***************************************************************************

add bx,16
trettertertertert:
;*************************************************************************
dec dx
jnz treertertertertertreerertert
pop dx
add esi,13
add bx,320*16-16*19
dec dx
jnz trettertyutyuuityyuityuityuiyuiyuiyui

mov [bombes],cx
ret

touches_action: ;--- bp: joeur en ce moment *4
PUSHALL

;-pour par k'on pose une bombe au début tout de suite kan meme...



cmp nombre_de_vbl_avant_le_droit_de_poser_bombe,0
je okokokok_pas_debut
dec nombre_de_vbl_avant_le_droit_de_poser_bombe
jmp treteterrterteterertter
okokokok_pas_debut:
;--------------
cmp [attente_avant_med],attente_avant_med2   ;uniquement si le processus
jb treteterrterteterertter                   ;de medaille est pas sur le point
                                             ;d'avoir lieu... plus de
                                             ; bombes

;--- maladie de la chiasse...
cmp word ptr [maladie+ebp],03 ;255 ; dd 8 dup (?)
je ertertrterteterrteert2rttyrrty
;---------------------------

inc [tribombe2+ebp]
;--- maladie de la constipation
cmp word ptr [maladie+ebp],05
je  treteterrterteterertter
;---------------------------

;----- touche action 1 ---
cmp byte ptr [ACTION+ebp],1
jne treteterrterteterertter
;------------------------
ertertrterteterrteert2rttyrrty:


;regarde si on peut poser une bombe...
mov edi,[infojoueur+ebp] ;dans edi: viseur sur l'info d'un joueur.
cmp dword ptr [edi],0  ;nombre de bombes qu'il peut encore poser.
je  treteterrterteterertter
push ebp
xy_to_offset
pop ebp
lea esi,[truc2+eax]

cmp byte ptr [esi],0 ;regarde si ya rien ou l'on veut placer la bombe
jne ya_une_bombeici
cmp byte ptr [esi-32*13],0 ;regarde si ya rien ou l'on veut placer la bombe
jne ya_une_bombeici


    PUSHALL
    pose_une_bombe
    POPALL
jmp treteterrterteterertter
ya_une_bombeici:
cmp [tribombe+ebp],0 ;que si on a le bonus
je treteterrterteterertter
cmp [tribombe2+ebp],20
ja treteterrterteterertter
cmp [tribombe2+ebp],2
ja ttrrttreteterrterteterertter
mov [tribombe2+ebp],0 ;remet a zero si on presse tjs
jmp treteterrterteterertter
ttrrttreteterrterteterertter:

;utilise Esi par rapport a truc2 pour gauche/droite.

;2eme generation
;sortie: ebx entree ebp...
direction_du_joueur 1

  PUSHALL ;(1)

encore_une_toto:

cmp dword ptr [edi],0  ;nombre de bombes qu'il peut encore poser.
jne nan_c_bon_on_peut_encore_poser
  POPALL  ;(1)
jmp treteterrterteterertter
nan_c_bon_on_peut_encore_poser:

   add esi,ebx
   add eax,ebx
    cmp byte ptr [esi],0 ;regarde si ya rien ou l'on veut placer la bombe
    je ici_toto
  POPALL  ;(1)
jmp treteterrterteterertter
    ici_toto:
    cmp byte ptr [esi-32*13],0 ;regarde si ya rien ou l'on veut placer la bombe
    je ici_toto2
  POPALL  ;(1)
jmp treteterrterteterertter
    ici_toto2:
mov playSoundFx,1
       PUSHALL
        pose_une_bombe
       POPALL
jmp encore_une_toto
treteterrterteterertter:

cmp playSoundFx,1
jne dfgjhldfgkhjdflgkjhdfkljhdfglkjhdfglkjhgdfyeah
bruit2 9,34 ;,BLOW_WHAT2 ;bruit du bonus tri bombe.
mov playSoundFx,0
dfgjhldfgkhjdflgkjhdfkljhdfglkjhdfglkjhgdfyeah:

;---------- touche action 2 -----------
;***
;PUSHALL
;mov ah,02h ;SUPER_SIGNE2 DB 0
;mov dl,13
;int 21h
;xor eax,eax
;shr ebp,1
;mov ax,word ptr [donnee+nb_dyna*2+ebp] ;recup Y
;add ax,14
;and ax,00000000000001111B
;call affsigne
;POPALL
;***


PUSHALL
cmp byte ptr [ACTION+2+ebp],1
jne treteterrterteterertteruiotyterertertterert
;2 possibilites vertical ou pas vertical


  cmp [lapipipino+ebp],0
  je treteterrterteterertteruiotyterertertterert
  cmp [lapipipino2+ebp],0
  jne treteterrterteterertteruiotyterertertterert

;saut de lapin le lapin...
bruit3 10,32,BLOW_WHAT2 ;bruit kan 1 lapin saute

;sortie: ebx entree ebp...
direction_du_joueur 2

push ebp ebx
xy_to_offset
lea esi,[truc+eax]
pop ebx ebp

mov [lapipipino3+ebp],duree_saut
mov [lapipipino2+ebp],1 ;saut vertical


;cas particulier: le lapin est ;en bas
cmp ebx,32*2
jne ertytyyuttyuyuiyuiiyyuiiyuiyu2
cmp eax,32*10
ja erterererererertert
ertytyyuttyuyuiyuiiyyuiiyuiyu2:

;cas particulier: le lapin est en haut:
cmp ebx,-32*2
jne ertytyyuttyuyuiyuiiyyuiiyuiyuo
cmp eax,32*2
jb erterererererertert
ertytyyuttyuyuiyuiiyyuiiyuiyuo:

;========== cas pqrticulier: on veut sauter une brike ==========
;il ne faut pas ke lon soit pas au milieu d'une brike
cmp ebx,-32*2
jne biooooiiii
cmp byte ptr [esi+ebx+32],0 ;une brike ?
je biooooiiii
au_milieu_y2 erterererererertert2
biooooiiii:
cmp ebx,32*2
jne biooooiiiiE2
cmp byte ptr [esi+ebx-32],0 ;une brike ?
je biooooiiiiE2
au_milieu_y2 erterererererertert2
biooooiiiiE2:
cmp ebx,2
jne biooooiiiiE24
cmp byte ptr [esi+ebx-1],0 ;une brike ?
je biooooiiiiE24
au_milieu_X2 erterererererertert2
biooooiiiiE24:
cmp ebx,-2
jne biooooiiiiE24y
cmp byte ptr [esi+ebx+1],0 ;une brike ?
je biooooiiiiE24y
au_milieu_X2 erterererererertert2
biooooiiiiE24y:
;)===================================================================


;---------------------------------------


cmp byte ptr [esi+ebx],0 ;si ya rien a l'endroit ou on va sauter
jne erterererererertert

;-- 3 cases a gauche
cmp ebx,-2
jne iuertytyyuttyuyuiyuiiyyuiiyuiyu

;--- si on est pas au milieu de la case en Y il faut verif ke on peut sauter
au_milieu_y

;la place est pas libre en face
;cmp [touches+ebp],128 ;si on avance pas
;jb  herterererererertert ;on saute a la verticale
;mov [lapipipino2+ebp],1 ;saut vertical
;jmp erterererererertert
;herterererererertert:
;mov [lapipipino3+ebp],0
;mov [lapipipino2+ebp],0 ;pés de saut
;jmp treteterrterteterertteruiotyterertertterert
;
;erterererererertertYUTYUyutyuu:

; pour etre sur kon va pas avancer sur cette case
;-- si elle est dur en effet on pourrait deborder
push eax
push ebp
shr ebp,1
xor eax,eax
mov ax,word ptr [donnee+ebp] ;recup X
add ax,3
and ax,1111B
pop ebp
cmp byte ptr [esi+ebx-1],0 ;pas vide a 3 cases a gauche
je iuokeeey
cmp ax,7
ja iuokeeey
push eax
sub eax,7
sub [lapipipino7+ebp],eax
pop eax
iuokeeey:
pop eax
iuertytyyuttyuyuiyuiiyyuiiyuiyu:
;------

;-- 3 cases a droite
; pour etre sur kon va pas avancer sur cette case
;-- si elle est dur en effet on pourrait deborder
cmp ebx,+2
jne iiuertytyyuttyuyuiyuiiyyuiiyuiyu

;--- si on est pas au milieu de la case en Y il faut verif ke on peut sauter
au_milieu_y
;------------------------------

push eax
push ebp
shr ebp,1
xor eax,eax
mov ax,word ptr [donnee+ebp] ;recup X
add ax,3
and ax,1111B
pop ebp
cmp byte ptr [esi+ebx+1],0 ;pas vide a 3 cases a gauche
je iiuokeeey
cmp ax,8
jb iiuokeeey
push eax
sub eax,7
add [lapipipino7+ebp],eax
pop eax
iiuokeeey:
pop eax
iiuertytyyuttyuyuiyuiiyyuiiyuiyu:
;------

;en bas ???
; pour etre sur kon va pas avancer sur cette case
;-- si elle est dur en effet on pourrait deborder
cmp ebx,32*2
jne nooooooooooooooooooooi
;saut vers le bas, avec truc dur a 3 cases dessous

;--- si on est pas au milieu de la case en X il faut verif ke on peut sauter
au_milieu_x



;;---- donc on regarde si ya du dur juste en dessous de lendroit ========
;;     ou on va atterir, car on pourrait deborder...
;; ou on va arriver
push eax
push ebp
shr ebp,1
xor eax,eax
mov ax,word ptr [donnee+nb_dyna*2+ebp] ;recup Y
add ax,14
and ax,00000000000001111B
pop ebp
cmp byte ptr [esi+ebx+32],0 ;pas vide a 3 cases en dessous ?
je uokeeey
cmp ax,8
jb uokeeey
push eax
sub eax,7
add [lapipipino7+ebp],eax
pop eax
uokeeey:
pop eax
nooooooooooooooooooooi:

;en haut
; pour etre sur kon va pas avancer sur cette case
;-- si elle est dur en effet on pourrait deborder
cmp ebx,-32*2 ;en haut
jne knooooooooooooooooooooi

;--- si on est pas au milieu de la case en X il faut verif ke on peut sauter
au_milieu_x

;saut vers le bas, avec truc dur a 3 cases dessous
;;---- donc on regarde si ya du dur juste en dessous de lendroit ========
;;     ou on va atterir, car on pourrait deborder...
;; ou on va arriver
push eax
push ebp
shr ebp,1
xor eax,eax
mov ax,word ptr [donnee+nb_dyna*2+ebp] ;recup Y
add ax,14
and ax,00000000000001111B
pop ebp
cmp byte ptr [esi+ebx-32],0 ;pas vide a 3 cases au dessus
je kuokeeey                 ;pour cas particulier, on est avance vers le
cmp ax,7                    ;bas... donc on serra avance sur une case dure
ja kuokeeey
  push eax
  sub eax,7
  neg eax
  add [lapipipino7+ebp],eax
  pop eax
kuokeeey:
pop eax
knooooooooooooooooooooi:
;;---===================================================================

erterererererertert:
jmp baaaaaaaaaaa
erterererererertert2:   ;pour pas sauter a la verticale,dans tous les cas
cmp [touches+ebp],127   ;si on avance pas
ja baaaaaaaaaaa         ;on saute a la verticale
mov [lapipipino3+ebp],0
mov [lapipipino2+ebp],0
baaaaaaaaaaa:
;--------

treteterrterteterertteruiotyterertertterert:
POPALL

mov ebx,[infojoueur+ebp] ;uniquement s'il y a droit...
cmp dword ptr [ebx+4*4],1
jne treteterrterteterertteruioty

cmp byte ptr [ACTION+1+ebp],1
jne treteterrterteterertteruioty
;liste_bombe dd ? ; nombre de bombes...
;            dd 247 dup (?,?,?,?)
mov ecx,[liste_bombe]
or ecx,ecx
jz pasdutout
lea esi,liste_bombe+4-taille_dune_info_bombe
next_bomby:
add esi,taille_dune_info_bombe
cmp dword ptr [esi+4],0
jne ya_bombe_ici
jmp next_bomby
ya_bombe_ici:
;------- unqieuemnt si c'est notre propre bombe...
mov ebx,[infojoueur+ebp]
cmp dword ptr [esi],ebx
jne non_dejar
;--------- uniquement si cette bombe est a retardement...
cmp word ptr [esi+4*3+2],0
je non_dejar
mov word ptr [esi+4*3+2],0 ;la transforme en bombe normalle
mov dword ptr [esi+4],1    ;la fait exploser
non_dejar:
dec ecx
jnz next_bomby
pasdutout:
;1er: offset de l'infojoeur
;2eme: nombre de tours avant que ca PETE !!! ; si = 0 ca veut dire
;                                            ;emplacement libre...
;3eme:distance par rapport au debut de truc2
;4eme puissance de la bombe.
treteterrterteterertteruioty:
;-----------------------------------------

POPALL
ret

minuteur: ;le tic tic tic des bombes...+ deplacement
PUSHALL

mov ecx,[liste_bombe]
or ecx,ecx
jz ertrteertertrterteertertertrteertertert
xor ebp,ebp

tetrrtyrtyrtyrtyrtyrtytyrtyr:
cmp dword ptr [liste_bombe+ebp+4+1*4],0 ;indique emplacement non remplis !!!
jne rtytyrrtytyrtyuutyiyuuiouiopuiouiopioppiopiopp2
inc ecx
jmp rtytyrrtytyrtyuutyiyuuiouiopuiouiopioppiopiopp
rtytyrrtytyrtyuutyiyuuiouiopuiouiopioppiopiopp2:

;*****-*-*-------********----------POUSSER DEPLACEMENT *-*-*********------

;add esi,[liste_bombe+ebp+4+2*4]  ;distance par rapport au debut de truc2
;mov word ptr [liste_bombe+ebx+4+4*4],1 ;adder X automatique.
;mov word ptr [liste_bombe+ebx+4+4*4+2],0
;mov word ptr [liste_bombe+ebx+4+5*4],0   ;adder X
;mov word ptr [liste_bombe+ebx+4+5*4+2],0 ;adder Y
;movsx eax,word ptr [liste_bombe+ebp+4+4*4] ;force d'addage.. (+1 ou -1)
;or  eax,eax
;je non_zero ;pas de force de deplacement X/Y
;add ebx,1 ;eax                     ;offset dans truc+addage
;--- réflechis au deplacement uniquement si on est a 0 en adder...
;cmp word ptr [liste_bombe+ebp+4+5*4],0
;jne depeplacement_kan_mee
;cmp byte ptr [truc+ebx],0
;jne non_ya_un_mur_ote ;mur a cote...
;depeplacement_kan_mee:
;on deplace....
;jne nan_nan_normale

;xy_adder 0 ou 2
;xy_x32   1 ou 32

;truc_monstre db 32*13 dup (?)

call deplacement_bombes


cmp action_replay,0
jne nononono_onest_en_recordplayzrezerzeezr
cmp twice,1
jne nononono_onest_en_recordplayzrezerzeezr
call deplacement_bombes
nononono_onest_en_recordplayzrezerzeezr:

;mov word ptr [liste_bombe+ebp+4+5*4],-7
;-----------
;mov ax,word ptr [liste_bombe+ebp+4+5*4]
;mov ebx,[liste_bombe+ebp+4+2*4]
;mov byte ptr [truc_X+ebx],al
;jmp okey_abe
;mov word ptr [liste_bombe+ebp+4+4*4],0
;okey_abe:
;non_zero:

;------------------ sauf si on a les bombes a retardement
;liste_bombe dd ? ; nombre de bombes...
;            dd 247 dup (?,?,?,?)
;1er: offset de l'infojoeur
;2eme: nombre de tours avant que ca PETE !!! ; si = 0 ca veut dire
;3eme:distance par rapport au debut de truc2
;4eme:DD= 1 DW: puissance de la bombe + 1 DW: bombe a retardement ??? (=1)

;mov ebx,[liste_bombe+ebp+4]
;cmp dword ptr [ebx+4*4],1

mov esi,offset truc2
add esi,[liste_bombe+ebp+4+2*4]  ;distance par rapport au debut de truc2

;---- cas particulier.. on est une bombe, est on vient de se prendre
;une brike sur la gueule... donc on explose...
cmp byte ptr [esi-32*13],11 ;cas particulier... apres apocalypse...
jne kklmjjkjklmklmjmjklmjklmjklmjkl
;on la fait exploser de suite...
mov dword ptr [liste_bombe+ebp+4+1*4],1 ;pour ke ca pete :))
mov word ptr [liste_bombe+ebp+4+3*4+2],0 ;elle est plus retarde (enfin
                                         ;plus.. maintenant. si elle l'etait)
jmp finis_la
kklmjjkjklmklmjmjklmjklmjklmjkl:
;----

cmp word ptr [liste_bombe+ebp+4+3*4+2],1 ;si bombe retardee...
je rertertertert                         ;ne decremente pas

finis_la:
dec dword ptr [liste_bombe+ebp+4+1*4]
jnz rertertertert

dec dword ptr [liste_bombe]
;------------ fait exploser la bombe -------------------------------------
;bruit 1 40 BLOW_WHAT2

cmp byte ptr [esi-32*13],11 ;cas particulier... apres apocalypse...
je nononononiioiouuio
mov byte ptr [esi],05 ;centre.
bruit2 2,40
nononononiioiouuio:

mov eax,[liste_bombe+ebp+4+0*4] ;offset de l'infojoeur
inc dword ptr [eax] ;augmente le nombre de bombe k'il a le droit de poser...
;,explosion ; -32 33 40

cmp byte ptr [esi-32*13],11 ;cas particulier... apres apocalypse... (pice dure)
je nononononiioiouuiorytrty
explosion -32,33,40
explosion 32,33,47
explosion 1,12,26
explosion -1,12,19
nononononiioiouuiorytrty:

;mov dword ptr [liste_bombe+ebp+4+3*4]
mov dword ptr [liste_bombe+ebp+4+0*4],0
mov dword ptr [liste_bombe+ebp+4+1*4],0
mov dword ptr [liste_bombe+ebp+4+2*4],0
mov dword ptr [liste_bombe+ebp+4+3*4],0
mov dword ptr [liste_bombe+ebp+4+4*4],0
mov dword ptr [liste_bombe+ebp+4+5*4],0

;----------------------------------------------------------------------
rertertertert:

rtytyrrtytyrtyuutyiyuuiouiopuiouiopioppiopiopp:
add ebp,taille_dune_info_bombe
dec ecx
jnz tetrrtyrtyrtyrtyrtyrtytyrtyr

ertrteertertrterteertertertrteertertert:

POPALL
ret
;ya un draw game ??? ou une victoire ???
;mov ecx,8
;mov edi,offset victoires
;xor eax,eax
;rep stosd

phase:
pushad

;-- special... draw forcé ---
cmp word ptr bdraw666,'99'
je dikgrhrfhgrrethghkgh


mov edi,offset vie
mov ecx,[nombre_de_dyna]
yretrteertertert:
cmp dword ptr [edi],1
je et_non_pas_de_draw
add edi,4
dec ecx
jnz yretrteertertert




;-------- si on est au temps = 0 on compte moins vite !!!!
;car c le bordel faut k'on ai le temps de voir...

;;cmp in_the_apocalypse,1
;;je pas_encore
;;----------------------

dec [attente_avant_draw]
jnz pas_encore
dikgrhrfhgrrethghkgh:
mov byte ptr [ordre2],'D'
cmp nombre_de_dyna,1
jne pas_encore
mov byte ptr [ordre2],'M'
pas_encore:
et_non_pas_de_draw:
;----------------------------- ya une victoire ???? ----------------------

xor ebx,ebx
xor edx,edx
xor edi,edi
mov eax,-1 ;equipe du dernier a avoir gagne..
mov ecx,[nombre_de_dyna]
uyretrteertertert:
cmp dword ptr [vie+edi],1
jne uil_est_mort

;team      dd 0,1,2,3,4,5,6,7
cmp eax,[team+edi] ;si deja un gagnant de cette équipe. on le compte pas.
je deja_dernier_un_gagnant_comme_ca
inc edx ;------- nombre de gagnants
mov eax,[team+edi] ;recup dans eax la team du gagnant...
mov ebx,edi ;sauvegarde du gagnant.
deja_dernier_un_gagnant_comme_ca:
uil_est_mort:
add edi,4
dec ecx
jnz uyretrteertertert



;//** cas particulier si mode 1 player... retourne edx = 1 si 1 seul vivant (moi)
cmp nombre_de_dyna,1
jne pasmode1player
mov ecx,8
mov edx,0
xor edi,edi
comptemonstresvivants:
cmp dword ptr [vie+edi],1
jne monstreMort
inc edx
monstreMort:
add edi,4
dec ecx
jnz comptemonstresvivants
pasmode1player:
;//**********

;// declenche victoire sur 2 joueur ou plus
cmp edx,1
jne terertyrtytyrrtyrty
; plus k'1 EQUIPE vivante... !!! !
; regarde si ya plus de bombes....

;dans eax on a l'equipe du gagnat
push eax
;-- transforme les bombes en semi-retardee
push ebx
xor ebx,ebx
ertterertuuuuu:
push ebx
mov ebx,[infojoueur+ebx]
;mov dword ptr [ebx+4*4],0
call nike_toutes_ses_bombes
pop ebx
add ebx,4
cmp ebx,32
jne ertterertuuuuu
pop ebx
;--------
pop eax

; juste pour la premiere fois... pour k'on ne pose plus de bombes.

cmp [attente_avant_med],attente_avant_med2
jne reterertertertr89
mov [attente_avant_med],attente_avant_med2-1
reterertertertr89:

;cmp word ptr [bombes],0
;jne terertyrtytyrrtyrty
mov esi,offset truc2
mov ecx,32*13
zertertrtertetyrtyutyuiuiy:
cmp byte ptr [esi],0
je terertyrtytyrrtyrtyert
cmp byte ptr [esi],54
jb terertyrtytyrrtyrty ;bombe trouvée...
terertyrtytyrrtyrtyert:
inc esi
dec ecx
jnz zertertrtertetyrtyutyuiuiy
;truc2   db 32*13 dup (?)
;           40
;           33
;     19 12 05 12 26
;           33
;           47
;1 = bombe... (2,3,4) respirant... si c sup a 4; on est mort...
;5 = centre de bombe. de 5 a 11
;12 = ligne droite...
;19 = arrondie ligne droite vers la gauche...
;26 = arrondie ligne droite vers la droite
;33 = ligne verti
;40 arrondie verti vers le haut
;47-- bas

;---------- regarde si on est dans un terrain ou il faut attendre ke l'apocalypse
;           soit terminee pour determiner un gagnant.
push ebx
mov bl,terrain
dec bl
shl ebx,2
cmp [ebx+kelle_fin],0
je pas_attente_fin_apocalypse
pop ebx
cmp in_the_apocalypse,1 ;c'est encore l'apo. decompte pas encore.
je terertyrtytyrrtyrty
push ebx
pas_attente_fin_apocalypse:
pop ebx

;;----------------------

dec [attente_avant_med]
jnz terertyrtytyrrtyrty
;fabriquation du packet/victoires&médailles

mov [ordre2],'Z'

;-------- on donne la victoire au tout premier de cette equipe
xor ebx,ebx
pas_celui_la:
cmp [team+ebx],eax
je reertertertertert90
add ebx,4
jmp pas_celui_la
reertertertertert90:

; si un joueur on zappe les medailles
cmp nombre_de_dyna,1
jne dfdfdfgkldgflkdgflkdlgklgdfl
mov [ordre2],'%'
dec dword ptr [victoires+ebx]
dfdfdfgkldgflkdgflkdlgklgdfl:
;

inc dword ptr [victoires+ebx]
mov [latest_victory],ebx

skynet_team_victory:
cmp [team3_sauve],4
jne copy_victory_data

mov ecx,[nombre_de_dyna]
mov esi,[team+ebx]
xor edi,edi

skynet_team_victory_loop:
cmp esi,[team+edi]
jne skynet_team_victory_next
cmp edi,[latest_victory]
je skynet_team_victory_next

inc dword ptr [victoires+edi]

skynet_team_victory_next:
add edi,4
dec ecx
jne skynet_team_victory_loop

copy_victory_data:
push ds
pop  es
mov esi,offset victoires
mov edi,offset donnee4
mov ecx,9
rep movsd
;--- puis on copie:
;les  4 dd: des sources du dyna de face ki a gagné...
;puis 1 db: le nombre de lignes k'il fait...
;liste_couleur dd offset blanc,

mov esi,[liste_couleur+ebx]
xor eax,eax
mov ax,word ptr [esi]
add eax,dword ptr [donnee+8*3*2+ebx] ;--- adresse page
stosd
xor eax,eax
mov ax,word ptr [esi+2]
add eax,dword ptr [donnee+8*3*2+ebx] ;--- adresse page
stosd
xor eax,eax
mov ax,word ptr [esi+4]
add eax,dword ptr [donnee+8*3*2+ebx] ;--- adresse page
stosd
xor eax,eax
mov ax,word ptr [esi+6]
add eax,dword ptr [donnee+8*3*2+ebx] ;--- adresse page
stosd
shr ebx,1
mov ax,word ptr [donnee+8*5*2+ebx]   ;--- nombre de lignes
stosb
mov ax,word ptr [donnee+8*6*2+ebx]   ;--- nombre de colones.
stosb

;--- puis copie les noms des différents joueurs...
mov edi,offset briques
xor ebx,ebx
erertcharmant:
mov esi,offset nick_t
add esi,[control_joueur+ebx]
;lodsd
movsd
add ebx,4
cmp ebx,4*8
jne erertcharmant
;-------------------------------------------------------

;mov dword ptr [texte1+6*1+1+32*0+edx],eax
;mov dword ptr [texte1+6*1+1+32*1+edx],eax
;mov dword ptr [texte1+6*1+1+32*2+edx],eax
;mov dword ptr [texte1+6*1+1+32*3+edx],eax


;donnee       dw 8 dup (?) ;x du dynablaster
;             dw 8 dup (?) ;y du dynablaster
;             dw 8 dup (?) ;source du dyna dans bloque
;             dd 8 dup (?) ;source bloque memoire
;             dw 8 dup (?) ;nombre de lignes pour un dyna...
;             dw 8 dup (?) ;nombre de colonnes.
;             dd 8 dup (?) ;adder di (pour la girl + grande...)
;liste_couleur dd 8 dup (?)

;donnee4+9*4+4*4

;mov ecx,4
;lodsw
;rep movsd ;des sources du dyna de face ki a gagné...
;stosd

;;donnee  dw 8*3 dup (?)
;;       dw 20,20,277,277,116,116,180,180  ;x du dynablaster
;;       dw 9,170,9,170,41,137,41,137 ;y du dynablaster
;;       dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna dans bloque
;;dd 576000,576000,576000,576000,640000,640000,640000,640000 ;source bloque memoire
;;dw 23,23,23,23,25,25,25,25 ;nombre de lignes pour un dyna...
;;dd 0,0,0,0,-3*320,-3*320,-3*320,-3*320 ;adder di (pour la girl + grande...)


;si ordre2='Z'
;       copie de "victoires dd 8 dup (?)"
;       et 1 dd avec le offset du dernier ki a eu une victoire...
;          (latest_victory)

terertyrtytyrrtyrty:


popad
ret
gestion_jeu endp




;touches dd nb_dyna dup (0)

                      ;0= face        bas.
                      ;8= droite      droite
                      ;16= gauche     gauche
                      ;24= haut       haut

load_data proc near

cmp dataLoaded,1
jne doTheLoad
RET
doTheLoad:
mov dataLoaded,2

PUSHALL

call load_gus


;------------------- charge le fichier avec les sprites ---------------

;mov ecx,[packed_liste+4*6]
;mov edx,offset iff_file_name
;mov edi,offset buffer4 ; 128000  ;307200
;mov ebx,320*200 ;307200
;mov ax,ds
;call load_pcx

;mov esi,0
;copyblock2
;-----------------------------------------------------------------------

;mov ecx,0
;mov edx,offset fichier1
mov ecx,[packed_liste+4*0]
mov edx,offset iff_file_name
;adresse_des_fonds dd 640000,64000,328000
mov edi,0
mov ebx,320*200 ;307200 ;nombre de pixels.

mov ax,fs
call load_pcx

;mov ecx,0
;mov edx,offset fichier2
mov ecx,[packed_liste+4*1]
mov edx,offset iff_file_name

mov edi,64000*2
mov ebx,320*200 ;307200

 mov ax,fs
call load_pcx

;mov ecx,0
;mov edx,offset fichier3

;---- game
mov ecx,[packed_liste+4*2]
mov edx,offset iff_file_name
mov edi,64000*3 ; 128000  ;307200
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- draw 1  ----
mov ecx,[packed_liste+4*7]
mov edx,offset iff_file_name
mov edi,64000*5
mov ebx,320*200
mov ax,fs
call load_pcx
;----------------

;--- draw2   ----
mov ecx,[packed_liste+4*8]
mov edx,offset iff_file_name
mov edi,64000*6
mov ebx,320*200
mov ax,fs
call load_pcx
;----------------

;--- med 1   ----
mov ecx,[packed_liste+4*9]
mov edx,offset iff_file_name
mov edi,64000*7
mov ebx,320*200
mov ax,fs
call load_pcx
;----------------

;--- med 3   ----
mov ecx,[packed_liste+4*10]
mov edx,offset iff_file_name
mov edi,64000*8
mov ebx,320*200
mov ax,fs
call load_pcx
;----------------

;--- sprites bomberman masculins ---
mov ecx,[packed_liste+4*3]
mov edx,offset iff_file_name
mov edi,576000 ; 128000  ;307200
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- sprites bomberman feminin ---
mov ecx,[packed_liste+4*6]
mov edx,offset iff_file_name
mov edi,640000 ; 128000  ;307200
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- vic 1 ---
mov ecx,[packed_liste+4*11]
mov edx,offset iff_file_name
mov edi,704000 ; 128000  ;307200
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- vic 2 ---
mov ecx,[packed_liste+4*12]
mov edx,offset iff_file_name
mov edi,768000 ; 128000  ;307200
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- vic 3 ---
mov ecx,[packed_liste+4*13]
mov edx,offset iff_file_name
mov edi,832000 ; 128000  ;307200
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- vic 4 ---
mov ecx,[packed_liste+4*14]
mov edx,offset iff_file_name
mov edi,896000 ; 128000  ;307200
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- neige1 ---
mov ecx,[packed_liste+4*15]
mov edx,offset iff_file_name
mov edi,896000+64000*3 ; 128000  ;307200
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- neige2 ---
mov ecx,[packed_liste+4*16]
mov edx,offset iff_file_name
mov edi,896000+64000*2 ; 128000  ;307200
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- pic.pcx ---
mov ecx,[packed_liste+4*18]
mov edx,offset iff_file_name
mov edi,896000+64000*1 ;896000+64000*3 ; 128000  ;307200
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;;--- mrfond.pcx ---
;mov ecx,[packed_liste+4*19]
;mov edx,offset iff_file_name
;;cmp kel_pic_intro,1
;;jne opiopiioiouuiiuiuiuooo
;;
;mov edi,896000+64000*4 ; 128000  ;307200
;mov ebx,640*(36*2) ;307200
;mov ax,fs
;call load_pcx
;

;;--- mrfond.pcx ---
mov ecx,[packed_liste+4*19]
mov edx,offset iff_file_name
;;cmp kel_pic_intro,1
;;jne opiopiioiouuiiuiuiuooo
;;
mov edi,1966080+64000*21
mov ebx,320*200
mov ax,fs
call load_pcx


;--- final.pcx ---
mov ecx,[packed_liste+4*20]
mov edx,offset iff_file_name
mov edi,896000+64000*4+640*(36*2) ; 128000  ;307200
mov ebx,320*200
mov ax,fs
call load_pcx
;;--nuage1.pcx--
mov ecx,[packed_liste+4*21]
mov edx,offset iff_file_name
mov edi,896000+64000*4+640*(36*2)+64000 ; 128000  ;307200
mov ebx,320*200
mov ax,fs
call load_pcx
;--nuage2.pcx--
mov ecx,[packed_liste+4*22]
mov edx,offset iff_file_name
mov edi,896000+64000*4+640*(36*2)+64000*2 ; 128000  ;307200
mov ebx,320*200
mov ax,fs
call load_pcx


;--- foret.pcx ---
mov ecx,[packed_liste+4*23]
mov edx,offset iff_file_name
mov edi,896000+384000+46080+64000 ; 128000  ;307200
mov ebx,320*200
mov ax,fs
call load_pcx

;--- feuille.pcx ---
mov ecx,[packed_liste+4*24]
mov edx,offset iff_file_name
mov edi,896000+384000+46080+64000+64000 ; 128000  ;307200
mov ebx,320*200
mov ax,fs
call load_pcx

;--- neige3 ---
mov ecx,[packed_liste+4*17]
mov edx,offset iff_file_name
mov edi, 896000+384000+46080+64000*3
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;1582080

;--- pause.pcx ---
mov ecx,[packed_liste+4*25]
mov edx,offset iff_file_name
mov edi,1582080
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- mdec.pcx ---
mov ecx,[packed_liste+4*26]
mov edx,offset iff_file_name
mov edi,1582080+64000
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;--- mdeg.pcx ---
mov ecx,[packed_liste+4*27]
mov edx,offset iff_file_name
mov edi,1582080+64000*2
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;;--- exo1.pcx ---
;mov ecx,[packed_liste+4*28]
;mov edx,offset iff_file_name
;mov edi,1582080+64000*3
;mov ebx,320*200
;mov ax,fs
;call load_pcx
;
;;--- puzzle.pcx ---
;mov ecx,[packed_liste+4*29]
;mov edx,offset iff_file_name
;mov edi,1582080+64000*4
;mov ebx,320*200
;mov ax,fs
;call load_pcx
;

;---- record0.mbr ---
;cmp special_on_a_loadee_nivo,1
;je naoinoirzeniozerrzeerzzererz
mov ecx,[packed_liste+4*30]
mov edx,offset iff_file_name

;cmp economode,1
;je ertertterterrtertytyrrtyrtyrtyrtyrtyrtyrty
;
;cmp special_on_a_loadee_nivo,1
;jne ertertterterrtertytyrrtyrtyrtyrtyrtyrtyrty
;lea edx,reccord2
;xor ecx,ecx
;
;ertertterterrtertytyrrtyrtyrtyrtyrtyrtyrty:

mov edi,1966080+64000
call load_raw

naoinoirzeniozerrzeerzzererz:
;---- record1.mbr ---
mov ecx,[packed_liste+4*31]
mov edx,offset iff_file_name
mov edi,1966080+64000*2
call load_raw

;---- record2.mbr ---
mov ecx,[packed_liste+4*32]
mov edx,offset iff_file_name
mov edi,1966080+64000*3
call load_raw

;---- record3.mbr ---
mov ecx,[packed_liste+4*33]
mov edx,offset iff_file_name
mov edi,1966080+64000*4
call load_raw

;---- fete1.mbr ---
mov ecx,[packed_liste+4*34]
mov edx,offset iff_file_name
mov edi,1966080+64000*5
call load_raw

;---- record5.mbr ---
mov ecx,[packed_liste+4*37]
mov edx,offset iff_file_name
mov edi,1966080+64000*6
call load_raw


;---- crayon.pcx ---
mov ecx,[packed_liste+4*35]
mov edx,offset iff_file_name
mov edi,1582080+64000*3 ;1582080+64000*6
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;---- crayon2.pcx ---
mov ecx,[packed_liste+4*36]
mov edx,offset iff_file_name
mov edi,1582080+64000*4 ;1582080+64000*7
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;---- lapin1.pcx ---
mov ecx,[packed_liste+4*38]
mov edx,offset iff_file_name
mov edi,1966080+64000*7
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx


;---- mort.pcx ---
mov ecx,[packed_liste+4*39]
mov edx,offset iff_file_name
mov edi,1966080+64000*8
mov ebx,320*200
mov ax,fs
call load_pcx


;---- lapin2.pcx ---
mov ecx,[packed_liste+4*40]
mov edx,offset iff_file_name
mov edi,1966080+64000*9
mov ebx,320*200
mov ax,fs
call load_pcx


;---- lapin3.pcx ---
mov ecx,[packed_liste+4*41]
mov edx,offset iff_file_name
mov edi,1966080+64000*10
mov ebx,320*200
mov ax,fs
call load_pcx


;---- lapin4.pcx ---
mov ecx,[packed_liste+4*42]
mov edx,offset iff_file_name
mov edi,1966080+64000*11
mov ebx,320*200
mov ax,fs
call load_pcx


;---- foot.pcx ---
mov ecx,[packed_liste+4*43]
mov edx,offset iff_file_name
mov edi,1966080+64000*12
mov ebx,320*200
mov ax,fs
call load_pcx


;---- foot1.mbr ---
mov ecx,[packed_liste+4*44]
mov edx,offset iff_file_name
mov edi,1966080+64000*13
call load_raw


;---- foot2.mbr ---
mov ecx,[packed_liste+4*45]
mov edx,offset iff_file_name
mov edi,1966080+64000*14
call load_raw


;---- fete2.mbr ---
mov ecx,[packed_liste+4*46]
mov edx,offset iff_file_name
mov edi,1966080+64000*15
call load_raw


;---- neige2.mbr ---
mov ecx,[packed_liste+4*47]
mov edx,offset iff_file_name
mov edi,1966080+64000*16
call load_raw

;---- rose2.mbr ---
mov ecx,[packed_liste+4*48]
mov edx,offset iff_file_name
mov edi,1966080+64000*17
call load_raw

;---- jungle2.mbr ---
mov ecx,[packed_liste+4*49]
mov edx,offset iff_file_name
mov edi,1966080+64000*18
call load_raw

;---- micro2.mbr ---
mov ecx,[packed_liste+4*50]
mov edx,offset iff_file_name
mov edi,1966080+64000*19
call load_raw

;---- nuage2.mbr ---
mov ecx,[packed_liste+4*51]
mov edx,offset iff_file_name
mov edi,1966080+64000*20
call load_raw


;--- soucoupe.pcx ---
mov ecx,[packed_liste+4*52]
mov edx,offset iff_file_name
mov edi,1966080+64000*22
mov ebx,320*200
mov ax,fs
call load_pcx


;--- soccer.pcx ---
mov ecx,[packed_liste+4*53]
mov edx,offset iff_file_name
mov edi,1966080+64000*23
mov ebx,320*200
mov ax,fs
call load_pcx


;--- footanim.pcx ---
mov ecx,[packed_liste+4*54]
mov edx,offset iff_file_name
mov edi,1966080+64000*24
mov ebx,320*200
mov ax,fs
call load_pcx



;---- lune1.mbr ---
mov ecx,[packed_liste+4*55]
mov edx,offset iff_file_name
mov edi,1966080+64000*25
call load_raw

;---- lune2.mbr ---
mov ecx,[packed_liste+4*56]
mov edx,offset iff_file_name
mov edi,1966080+64000*26
call load_raw



;---- bombes.+ sprites bonus (sprite2.pcx)
mov ecx,[packed_liste+4*4]
mov edx,offset iff_file_name
mov edi,1582080+64000*5
mov ebx,320*200 ;307200
mov ax,fs
call load_pcx

;------------------------
;(1582080+64000*6) 64000K réservé pour sauvegarde
;
;
;------------------------

;--- menu... ----
mov ecx,[packed_liste+4*5]
mov edx,offset iff_file_name
mov edi,64000*4
mov ebx,320*200
mov ax,fs
call load_pcx

;----------------


eretterertrerzet:
POPALL
ret
endp


transmet_central proc near ; é partir du GROS packet de touches qu'on a
                           ; récupéré pour tous les ordinateur.
                           ; on regarde é kel dyna correspond chaque partie
                           ; packet
                           ; et on modifie les variables CENTRAL "touches"
                           ; et "action"
                           ; qui informent dans kel direction le dyna va
                           ; s'il est en mouvement  et s'il veut poser une
                           ; bombes. grace a ces variables l'intelligence du
                           ; master déterminera les packets finaux a envoyer
                           ; ou différents slaves... (enfin é l'affichage koi)
PUSHALL
;*************** transmet au central...

mov ecx,[nombre_de_dyna] ;   dd 2 ;en tout.. pour le master
xor ebp,ebp
rterteterrterteertert:
mov ebx,[control_joueur+ebp] ;récupere l'offet du packet en question.

;controle joueur special play
cmp action_replay,2
jne pas_recertterteretrreertyutyyut
mov ebx,[control_joueur2+ebp] ;récupere l'offet du packet en question.
;mov ebx,-64
pas_recertterteretrreertyutyyut:
;=================

lea esi,[total_t+ebx]



;entrée. ebp ;numéro CENTRAL d'un joeur.

;mov esi,offset total_t ;packet

;call packet_to_central ;modifie les valeurs du central a partir des
;                       ;deplacement d'un dyna.
;packet_to_central proc near ;numéro du dyna * 4

PUSHALL

;model des packets recus par le master.. (envoyé par slave.)
;donnee2 dd 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
;        dd 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
;        dd 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
;        dd 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
;
;;offset 0         =1 si la fleche bas est pressé/               j1
;;       4         =1 si la fleche droite est pressé             j1
;;       8         =1 si la fleche gauche est pressé             j1
;;       12        =1 si la fleche haut est pressé2              j1
;;       16        =1 bouton 1                                   j1
;;       20        =1 bouton 2                                   j1

xor ax,ax ;indique k'on a trouvé aucune touche...

mov dword ptr [ACTION+ebp],0 ;touches action a 0

cmp [lapipipino+ebp],0 ;lapin ? tient pas compte de ses trucs
je dynanormalito
cmp [lapipipino2+ebp],0 ;en train de sauter ? tient pas compte de ses trucs
jne errereerreerretertertrtertetyyrtuui
dynanormalito:

cmp byte ptr [esi+3],1
jne erterertertertert
mov [touches+ebp],0
mov ax,1
 erterertertertert:

cmp byte ptr [esi+1],1
jne erterertertertert2
mov [touches+ebp],8
mov ax,2
 erterertertertert2:

cmp byte ptr [esi+2],1
jne erterertertertert3
mov [touches+ebp],16
mov ax,3
 erterertertertert3:

cmp byte ptr [esi],1
jne erterertertertert4
mov [touches+ebp],24
mov ax,4
 erterertertertert4:


;**************** touches d'action

;------------- touches d'action
;       4         =1 bouton 1                                   j1
;      5          =1 bouton 2                                   j1




cmp byte ptr [esi+4],1
jne ertertertertrte
mov byte ptr [ACTION+ebp],1
ertertertertrte:

cmp byte ptr [esi+6],1
jne ertertertertrte3
mov byte ptr [ACTION+ebp+2],1
; si lapin ki a la maladie de la lenteur... on lui permet pas de sauter ...
cmp word ptr [maladie+ebp],02 ;255 ; dd 8 dup (?)
jne ertertertertrte3
mov byte ptr [ACTION+ebp+2],0
;------------
ertertertertrte3:

;special lapin en train de sauter,on arrive directement la
errereerreerretertertrtertetyyrtuui:

cmp byte ptr [esi+5],1
jne tertertertertrte
mov byte ptr [ACTION+ebp+1],1
tertertertertrte:

;*******************************

;-------------
;touches dd nb_dyna dup (0)
;                      ;0= face        bas.
;                      ;8= droite      droite
;                      ;16= gauche     gauche
;                      ;24= haut       haut

;+128 si ne bouge pas..
or ax,ax
jnz reerrteertyut
or dword ptr [touches+ebp],128
reerrteertyut:
POPALL

add ebp,4
dec ecx
jnz rterteterrterteertert

POPALL
ret
endp

;get_all_infos proc near
;PUSHALL
;
;;1er mot 0=existe pas: 1 existe !!!
;;2eme mot: numéro de l'ordinateur !!!
;;        0= local.
;;3eme mot: numéro interne (0 a 3) pour chaque ordinateur.
;;liste_des_joeurs dd 1,0,0
;;                 dd 0,0,0
;
;xor ebp,ebp
;
;mov esi,offset liste_des_joeurs
;mov ecx,[nombre_de_dyna] ;   dd 2 ;en tout.. pour le master
;sauver_de_moi_meme:
;or ecx,ecx
;jz fini
;dec ecx
;;cmp dword ptr [esi],0
;;je fini
;
;
;cmp dword ptr [esi+4],0 ;regarde si le joueur en question est en local. sinon il faut
;              ;récupérer l'info par communication avec l'ordinateur.
;je cest_en_local
;
;cmp dword ptr [esi+8],0 ;regarde si on aurait pas deja récupéré le packet..
;                        ;(vrai si offset dans le packet <> 0...)
;jne cest_en_local ;deja fait...
;
;;communication. (si le packet n'est pas deja chargé...)
;;**************************************************************************
;ytytytytttttttttttttttttttttt:
;PUSHALL
;mov esi,[esi+4] ;offset liste_adresse ;récupere l'adresse de l'ordy ou on envois... ;offset adresse
;mov ebp,offset packed_data ;donnee
;;call envois
;;envois special bloc total...
;envois3 ecb2 header_envois socket_jeu
;POPALL
;;call ecoute
;ecoute2 ecb1 recu_data header_ecoute touches_size socket_jeu
;
;xor ax,ax
;erzertrteertertert1:
;
;     /********************************************************\
;cmp byte ptr [clavier+59],1 ;F1... donne la periode d'attente pour la comm
;                            ;avec un ordy...
;jne reertertertertertert
;;- raster vert -
;inc ax
;push dx ax
;   mov   dx,3c8h
;push ax
; xor ax,ax
;   out   dx,al
;   mov   dx,3c9h
;   out   dx,al
;pop ax
;   out   dx,al
;xor ax,ax
;   out   dx,al
;pop ax dx
;;- raster vert -
;reertertertertertert:
;;     \********************************************************/
;cmp byte ptr [sortie],1 ;eSC.
;je rtyrtyrtyretertdgrfgdtrdfgdfgdfg
;cmp byte ptr [ecb1+8],0
;jne erzertrteertertert1
;;
;call raster2
;rtyrtyrtyretertdgrfgdtrdfgdfgdfg:
;;-------
;PUSHALL
;mov ax,gs
;mov es,ax
;;recu_data     db '??????????????????????????????????????????????????????????????',10,13,'$'
;mov esi,offset recu_data
;mov edi,offset donnee2
;mov ecx,6*4*4
;rep movsb
;POPALL
;
;;**************************************************************************
;cest_en_local:
;
;push esi
;mov esi,[esi+8] ;récupere l'offet du packet en question.
;add esi,offset donnee2 ;packet
;
;;entrée. ebp ;numéro CENTRAL d'un joeur.
;
;call packet_to_central ;modifie les valeurs du central a partir des
;                       ;deplacement d'un dyna.
;pop esi
;;------------------------------------------
;add ebp,4
;add esi,32
;jmp sauver_de_moi_meme
;fini:
;POPALL
;ret
;endp


possible_ou_pas proc near ;dx add x, cx: add y
PUSHALL

;add [donnee+nb_dyna*2+ebp],1 Y

;xy_to_offset
;lea esi,[truc+eax]

xor eax,eax
mov ax,[donnee+ebp] ;x !!!!
add ax,dx
add ax,3
shr ax,4

xor ebx,ebx
mov bx,[donnee+nb_dyna*2+ebp] ;Y !!!!
add bx,14
add bx,cx
;shr bx,4
and bx,01111111111110000B
shl bx,1 ;*32
mov esi,offset truc
add esi,ebx
add esi,eax

cmp byte ptr [esi],0
jne zerrzerzeerzer

;;1 = bombe... (2,3,4) respirant... si c sup a 4; on est mort...
cmp byte ptr [esi+32*13],1
jb efrerrereterter
cmp byte ptr [esi+32*13],4
ja efrerrereterter

add ebp,ebp
cmp [last_bomb+ebp],esi
je efrerrereterter

;--- ya une bombe+c'est pas la derniere case !!! essaye de la pousser ---

cmp [pousseur+ebp],1
jne zerrzerzeerzer
PUSHALL
cmp dx,0
je pas_eee
jns tjyuyu6754oooi
mov ax,-1
tjyuyu6754oooi:

cmp dx,0
js tjyuyu6754oooir
mov ax,1
tjyuyu6754oooir:

mov ecx,0
call pousse_la_bombe
jmp okeeeeeyiui
pas_eee:

cmp cx,0
je pas_eeerty
jns tjyuyu6754oooirr
mov ax,-1
tjyuyu6754oooirr:

cmp cx,0
js tjyuyu6754oooirt
mov ax,1
tjyuyu6754oooirt:

mov ecx,2
call pousse_la_bombe
pas_eeerty:

okeeeeeyiui:
POPALL

jmp zerrzerzeerzer
efrerrereterter:


xor cx,cx ;retourne jz=vrai
POPALL
ret

zerrzerzeerzer:

mov cx,1
or cx,cx ;retourne jz=faux

POPALL
ret
endp


;mov si,-16 ; ;16 ;8 haut.
;call remet_milieu_x

remet_milieu_x proc near ;replace le sprite au milieu d'un case.
PUSHALL
xor ebx,ebx
mov bx,[donnee+ebp] ;x !!!!
add bx,3
;------------------
and bx,01111B
cmp bx,7
je iookokokokok_deja_milieux
;dx add x, cx: add y
mov dx,0            ;X
mov cx,si           ;Y
call possible_ou_pas
jnz ertertirtyrtyyrtrtyrtyxer ;impossible.

;il n'y a rien juste au dessus/sous. remet vers le milieu...

eheheh_mur:

cmp bx,7
ja zererzerrteertrterteert
inc word ptr [donnee+ebp] ;x !!!!
xor cx,cx ;retourne jz=vrai
POPALL
ret
zererzerrteertrterteert:
dec word ptr [donnee+ebp] ;x !!!!
xor cx,cx ;retourne jz=vrai
POPALL
ret
;---------- ya kekchoz en dessous/sus
ertertirtyrtyyrtrtyrtyxer:

push ebp
add ebp,ebp
mov [avance+ebp],0 ;=0 PAS reussit a bouger
pop ebp


cmp bx,7
ja uzererzerrteertrterteert

;dx add x, cx: add y
mov dx,-16                     ;X
mov cx,si                      ;Y
call possible_ou_pas
jnz eheheh_mur
;dx add x, cx: add y
mov dx,-16                     ;X
mov cx,0                       ;Y
call possible_ou_pas
jnz eheheh_mur

dec word ptr [donnee+ebp] ;x !!!!
xor cx,cx ;retourne jz=vrai
POPALL
ret
uzererzerrteertrterteert:

mov dx,16
mov cx,si ;16 ;8
call possible_ou_pas
jnz eheheh_mur
mov dx,16 ;0
mov cx,0 ;si ;16 ;8
call possible_ou_pas
jnz eheheh_mur

inc word ptr [donnee+ebp] ;x !!!!
xor cx,cx ;retourne jz=vrai
POPALL
ret

iookokokokok_deja_milieux:
mov cx,1
or cx,cx ;retourne jz=faux
POPALL
ret
endp

remet_milieu_y proc near ;replace le sprite au milieu d'un case.
PUSHALL
xor ebx,ebx
mov bx,[donnee+nb_dyna*2+ebp] ;y !!!!
add bx,14 ;!
;------------------


and bx,01111B
cmp bx,7
je yiookokokokok_deja_milieux
;dx add x, cx: add y
mov dx,si
mov cx,0 ;16 ;8
call possible_ou_pas
jnz yertertirtyrtyyrtrtyrtyxer ;impossible.

impossible_2_fois:

;push ebp
;add ebp,ebp
;mov [avance+ebp],0 ;=0 PAS reussit a bouger
;pop ebp

cmp bx,7
ja yzererzerrteertrterteert
inc word ptr [donnee+nb_dyna*2+ebp] ;y !!!!
xor cx,cx ;retourne jz=vrai
POPALL
ret
yzererzerrteertrterteert:
dec word ptr [donnee+nb_dyna*2+ebp] ;y !!!!
xor cx,cx ;retourne jz=vrai
POPALL
ret
;---------- ya kekchoz en dessous
yertertirtyrtyyrtrtyrtyxer:

push ebp
add ebp,ebp
mov [avance+ebp],0 ;=0 PAS reussit a bouger
pop ebp



cmp bx,7
ja yuzererzerrteertrterteert

mov dx,si
mov cx,-16
call possible_ou_pas
jnz impossible_2_fois
mov dx,0
mov cx,-16
call possible_ou_pas
jnz impossible_2_fois


dec word ptr [donnee+nb_dyna*2+ebp] ;y !!!!
xor cx,cx ;retourne jz=vrai
POPALL
ret
yuzererzerrteertrterteert:

mov dx,si
mov cx,16
call possible_ou_pas
jnz impossible_2_fois
mov dx,0
mov cx,16
call possible_ou_pas
jnz impossible_2_fois


inc word ptr [donnee+nb_dyna*2+ebp] ;y !!!!
xor cx,cx ;retourne jz=vrai
POPALL
ret

yiookokokokok_deja_milieux:
mov cx,1
or cx,cx ;retourne jz=faux
POPALL
ret
endp

nouvelle_partie proc near
PUSHALL

push ds
pop  es

mov pauseur2,0
mov pause,0
mov pause2,50 ;interdiction de pause !!!


mov eax,[nombre_de_dyna]

push eax
shl eax,2
mov [nombre_de_dyna_x4],eax
pop eax

sub eax,8
neg eax
mov [nombre_de_monstres],eax
mov [nombre_de_monstres],eax

cmp [master],0
je trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2erte

POPALL
ret
;*************** QUE MASTER -******************
trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2erte:

mov ecx,8
mov edi,offset victoires
xor eax,eax
rep stosd

POPALL
ret
endp


nouvelle_manche proc near
PUSHALL

push ds
pop  es

;mov attente_avant_adder_inser_coin,60*20

;bdraw666 db '  '
;bdraw1  dd ? ;32
mov inser_coin,120
mov viseur_ic2,4
mov adder_inser_coin,320*(67+50)

mov [viseur_sur_fond],0
mov [duree_vic],duree_vic2

mov [attente_avant_draw],attente_avant_draw2
mov [attente_avant_med],attente_avant_med2
mov [duree_draw],duree_draw2
mov [duree_med],duree_med2

mov [attente_nouveau_esc],0

mov [affiche_pal],1
mov [ordre2],''
mov [sortie],0

cmp [master],0
je trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2ert

POPALL
ret
;*************** QUE MASTER -******************
trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2ert:

mov word ptr bdraw666,'03'
mov bdraw1,60
mov adder_bdraw,50*320
mov balance_le_bdrawn,0
mov temps2,59

mov special_nivo_6,0

mov acceleration,0

mov in_the_apocalypse,0

mov nombre_de_vbl_avant_le_droit_de_poser_bombe,nombre_de_vbl_avant_le_droit_de_poser_bombe2
cmp nombre_de_dyna,1
jne fdlkjdfkljdfglkgdjf
mov nombre_de_vbl_avant_le_droit_de_poser_bombe,0
fdlkjdfkljdfglkgdjf:


push ax
mov al,team3_sauve
and al,3
mov team3,al
pop ax

;---- terrain ---
mov ebx,[viseur_liste_terrain] ;dd 0
mov al,[liste_terrain+ebx]
mov [terrain],al
inc [viseur_liste_terrain]
cmp [liste_terrain+1+ebx],66
jne coolio
mov [viseur_liste_terrain],0
coolio:
;------------------


;;SI PLAY, terrain dans le header !!! + variable "changement" -------
cmp action_replay,2
jne ertrtertertyetyuyutyut

;cmp nombre_de_vbl_avant_le_droit_de_poser_bombe,0
;jne erterertrtertetertyutyuyuttyuuty
mov team3,0
push eax
;mov eax,fs:[1966080+TAILLE_HEADER_REC-9] ;variable changement
mov esi,replayer_saver4
mov eax,fs:[esi+TAILLE_HEADER_REC-9] ;variable changement

BIGENDIANPATCH eax
mov [changement],eax
;mov byte ptr al,fs:[1966080+TAILLE_HEADER_REC-1] ;1er octet: le numero du terrain
mov byte ptr al,fs:[esi+TAILLE_HEADER_REC-1] ;1er octet: le numero du terrain

mov [terrain],al
pop eax
ertrtertertyetyuyutyut:


;mov temps,duree_match

;push ax
;mov al,team3_sauve
;mov team3,al
;pop ax

cmp [team3],0
jne etrtyertyrdfgdfggdffgdgdfgy
PUSHALL
lea esi,n_team
lea edi,team
mov ecx,9
rep movsd
POPALL
etrtyertyrdfgdfggdffgdgdfgy:

cmp [team3],2
jne etrtyertyrdfgdfggdffgdgdf
PUSHALL
lea esi,s_team
lea edi,team
mov ecx,9
rep movsd
POPALL
etrtyertyrdfgdfggdffgdgdf:
cmp [team3],1
jne etrtyertyrdfgdfggdffgdgdfE
PUSHALL
lea esi,c_team
lea edi,team
mov ecx,9
rep movsd
POPALL
etrtyertyrdfgdfggdffgdgdfE:

;--- recup la duree du match en fonction du terrain
xor ebx,ebx
mov bl,terrain
dec bl
shl ebx,2
mov eax,[ebx+kelle_duree]
mov temps,ax
;----------------------------------------------------------
mov edi,offset total_t
xor eax,eax
mov ecx,(64/4)*8
rep stosd
lea edi,total_play
xor eax,eax
mov ecx,64/4
rep stosd

xor eax,eax
mov ecx,8 ;nb_dyna
lea edi,touches_save
rep stosd

;-------------------------------------------- données ...
mov edi,offset donnee

xor ebx,ebx
mov bl,terrain
dec bl
shl ebx,2
mov esi,[ebx+kelle_donnee]

;donnee_s_neige dw 20,20,277,277-32,116-16-16,116,180+16+16,180  ;x du dynablaster
;                dw 9,170,9,170,41,137,41,137-16-16 ;y du dynablaster

;--- X/Y avec rotation pour changer la place des dyna..
  xor edx,edx
  mov edx,[changement]
  and edx,01111B ;
  shl edx,5 ;*32

  ;******** ACTION REPLAY--------------------
  ; si play
  cmp action_replay,2
  jne pashjktrkhjerterttyr

push esi
  mov esi,replayer_saver4
  mov edx,dword ptr fs:[esi+TAILLE_HEADER_REC-5] ;rotation, offet 1 dans le header !
pop esi
  BIGENDIANPATCH edx

  pashjktrkhjerterttyr:

  mov ecx,8
  oooiiooiioio:
  mov ebx,[random_place+edx]
  mov ax,word ptr [esi+ebx]
  mov word ptr [edi],ax
  mov ax,word ptr [esi+ebx+8*2]
  mov word ptr [edi+8*2],ax
  add edi,2
  add edx,4
  dec ecx
  jnz oooiiooiioio
  add esi,8*4
  add edi,8*2
;------
mov ecx,8*14
rep movsb
mov edi,offset liste_couleur
mov ecx,8
rep movsd
lea edi,nombre_de_coups
mov ecx,8
rep movsd

mov edi,offset infos_j_n
mov ecx,5
rep movsd
lea edi,infos_m_n
mov ecx,5*8
rep movsd
lea edi,invinsible
mov ecx,8
rep movsd
lea edi,blocage
mov ecx,8
rep movsd

mov ecx,[nombre_de_dyna]
lodsd
lea edi,invinsible
rep stosd

mov ecx,[nombre_de_dyna]
lodsd
lea edi,blocage
rep stosd

lea edi,pousseur
mov ecx,8
rep movsd

lea edi,vitesse_monstre
mov ecx,8
rep movsd

mov ecx,[nombre_de_dyna]
lodsd
lea edi,pousseur
rep stosd

mov ecx,[nombre_de_dyna]
lodsd
lea edi,patineur
rep stosd

lea edi,correspondance_bonus
mov ecx,32/4
rep movsd


;info j.
mov edi,offset j1
mov ecx,[nombre_de_dyna]
;--- 1
push ecx
koaiouiouiouiououiuio:
mov eax,[infos_j_n]
stosd
mov eax,[infos_j_n+4]
stosd
mov eax,[infos_j_n+8]
stosd
mov eax,[infos_j_n+12]
stosd
mov eax,[infos_j_n+16]
stosd
dec ecx
jnz  koaiouiouiouiououiuio
pop ecx
mov eax,ecx
sub ecx,8
neg ecx
or ecx,ecx
jz centralol
;--- 8 POUR LES MONSTRES !!!
lea esi,infos_m_n
;on doit ajouter (4*5)*nombre joueurs en offset
erterertertert:
add esi,4*5
dec eax
jnz erterertertert

monstro4:
;mov eax,[infos_m_n]
;stosd
push ecx
mov ecx,5
rep movsd
pop ecx
;mov eax,[infos_m_n+4]
;stosd
;movsd
;mov eax,[infos_m_n+8]
;stosd
;movsd
;mov eax,[infos_m_n+12]
;stosd
;movsd
;xor eax,eax
;stosd
;movsd
;---
dec ecx
jnz monstro4
centralol:

;-- transforme les monstres par défaux en dynas ...
mov esi,offset s_normal
lea edi,donnee+8*6
mov ecx,[nombre_de_dyna]
rep movsd
lea esi,liste_couleur_normal
lea edi,liste_couleur ;(= donnee+8*18)
mov ecx,[nombre_de_dyna]
rep movsd
mov esi,offset l_normal
lea edi,donnee+8*10
mov ecx,[nombre_de_dyna]
rep movsw
mov esi,offset c_normal
lea edi,donnee+8*12
mov ecx,[nombre_de_dyna]
rep movsw
mov esi,offset a_normal
lea edi,donnee+8*14
mov ecx,[nombre_de_dyna]
rep movsd
lea esi,r_normal
lea edi,nombre_de_coups
mov ecx,[nombre_de_dyna]
rep movsd
i:

;donnee_s_neige dw 20,20,277,277-32,116-16-16,116,180+16+16,180  ;x du dynablaster
;       2        dw 9,170,9,170,41,137,41,137-16-16 ;y du dynablaster
;       4        dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna
;       6        dd 512000,512000,512000,512000,512000,512000,512000,512000 ;source bloque memoire
;       10       dw 32,32,32,32,32,32,32,32 ;nombre de lignes pour un dyna...
;       12       dw 32,32,32,32,32,32,32,32 ;nombre de colonnes.
;       14       dd -9*320-4,-9*320-4,-9*320-4,-9*320-4,-9*320-4,-9*320-4,-9*320-4,-9*320-4 ;adder di
;       18       dd offset grosbleu,offset grosbleu,offset grosbleu,offset grosbleu,offset grosbleu,offset grosbleu,offset grosbleu,offset grosbleu
;
;;avec un dyna...
;liste_couleur_normal dd blanc,offset bleu,offset vert,offset rouge,offset blancg,offset bleug,offset vertg,offset rougeg
;
;;       dw 20,20,277,277,116,116,180,180  ;x du dynablaster
;;       dw 9,170,9,170,41,137,41,137 ;y du dynablaster
;;       dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna dans bloque
;;       64000*8
;s_normal dd 512000,576000,576000,576000,640000,640000,640000,640000 ;source bloque memoire
;l_normal dw 23,23,23,23,25,25,25,25 ;nombre de lignes pour un dyna...
;c_normal dw 32,23,23,23,23,23,23,23 ;nombre de colonnes.
;a_normal dd 0,0,0,0,-3*320,-3*320,-3*320,-3*320 ;adder di (pour la girl + grande...)

;-----------------------------------

;briques dw 1+19*13*2 dup (?)  ;nombre de brique, source de la brique, destination
;                              ;dans buffer video
;bombes  dw 1+19*13*2 dup (?)  ; pareil pour les bombes & explosion & bonus
xor eax,eax
mov edi,offset briques
mov ecx,1+19*13*2
rep stosw
mov edi,offset bombes
mov ecx,1+19*13*2
rep stosw

mov edi,offset maladie
mov ecx,8
rep stosd

lea edi,clignotement
mov ecx,8
rep stosd

lea edi,tribombe
mov ecx,8
rep stosd
lea edi,tribombe2
mov ecx,8
rep stosd

lea edi,lapipipino ;pour pu kil soit considere comme un lapin
mov ecx,8
rep stosd
lea edi,lapipipino2 ;pour pu kil soit considere comme un lapin
mov ecx,8
rep stosd
lea edi,lapipipino3 ;pour pu kil soit considere comme un lapin
mov ecx,8
rep stosd
lea edi,lapipipino4 ;pour pu kil soit considere comme un lapin
mov ecx,8
rep stosd
lea edi,lapipipino5 ;pour pu kil soit considere comme un lapin
mov ecx,8
rep stosd
lea edi,lapipipino6 ;pour pu kil soit considere comme un lapin
mov ecx,8
rep stosd

xor ebx,ebx
mov bl,terrain
dec bl
shl ebx,2
mov esi,[ebx+kelle_truc]

mov edi,offset truc
mov ecx,32*13
rep movsb

;--
xor ebx,ebx
mov bl,terrain
dec bl
shl ebx,2
mov esi,[ebx+kelle_bonus]
mov edi,offset truc2
mov ecx,32*13
rep movsb
;---
;liste_bombe dd ? ; nombre de bombes...
;            dd 247 dup (?,?,?,?)
mov edi,offset liste_bombe
mov ecx,1+247*(taille_dune_info_bombe/4)
rep stosd

;touches dd nb_dyna dup (0)
;action, touches d'action appuyés pour chacun des joeurs...
;
;ACTION dw nb_dyna dup (0,0)

lea edi,avance2
mov eax,1
mov ecx,8
rep stosd

mov edi,offset touches

xor eax,eax
mov ecx,8
rep stosd
xor eax,eax

mov edi,offset action
mov ecx,8
rep stosd

;-------- choisit une apocalypse en fonction du terrain...
;lea esi,truc_fin_s
push ebx
mov bl,terrain
dec bl
shl ebx,2
mov esi,[ebx+kelle_apocalypse]
pop ebx
lea edi,truc_fin
mov ecx,13*32+4
rep movsb

;------------------------------- eax: -1
mov edi,offset vie
mov ecx,8
mov eax,1
rep stosd


;fabrique un last_bomb pour chaque dyna...(par rapport a la position de debut)

xor ebp,ebp
a6ans:
PUSHALL
  push ebp
  xy_to_offset
  pop ebp
  lea esi,[truc+eax]
  mov [last_bomb+ebp],esi
POPALL
add ebp,4
cmp ebp,4*8
jne a6ans

;mov [nomonster],1

cmp action_replay,0
jne nonononpasmode
cmp nomonster,1
jne nonononpasmode

;  jne nononono_onest_en_recordplay
;cmp twice,1
;jne nononono_onest_en_recordplay
;shr ecx,1
;nononono_onest_en_recordplay:

;----- tue tout le monde-
;cmp byte ptr [clavier+88],1 ;F12
;jne ertretetertertrte
mov edi,offset vie
xor ebp,ebp
mov ecx,[nombre_de_dyna]
retrteertertert:
or ecx,ecx
jz ljkljkmjkljklmljk
dec ecx
jmp trttyyrryrrryryryryr
ljkljkmjkljklmljk:
mov dword ptr [edi+ebp],14
trttyyrryrrryryryryr:

add ebp,4
cmp ebp,8*4
jnz retrteertertert
;ertretetertertrte:

nonononpasmode:


cmp action_replay,0 ;1
je pas_action

mov liste_bombbbb2,0
mov attente_entre_chake_bombe,0
mov viseur__nouvelle_attente_entre_chake_bombe,0

;viseur_change_in dd 0,4,8,12,16,20,24,28

PUSHALL
lea edi,avance
xor eax,eax
mov ecx,8
rep stosd

;viseur_change_in dd 0,4,8,12,16,20,24,28
;viseur_change_in_save dd 0,4,8,12,16,20,24,28 ;pour replay
lea esi,viseur_change_in_save
lea edi,viseur_change_in
xor eax,eax
mov ecx,8
rep movsd

POPALL

;STRUTURE DE REC:
TAILLE_HEADER_REC EQU 32
TAILLE_BONUS_REC EQU 256

;---------- REC ou  -------------
;PUSHALL ;hazard indesirable :) kan on enregistre :)
;push ds
;pop es
;lea edi,avance2
;mov eax,1
;mov ecx,8
;rep stosd
;POPALL


;si on rec, on initialise la veriable ki contiendra a la fin le nombre
; total de "tours"

;mov byte ptr fs:[1966080+TAILLE_HEADER_REC],1
;mov dword ptr fs:[1966080+TAILLE_HEADER_REC+TAILLE_BONUS_REC],4


pas_action:
;------------------------------
;(1582080+64000*6) 64000K réservé pour sauvegarde

POPALL
ret
endp

rec_play_touches proc near
PUSHALL

;***********************************************
;         PLAY !!!  é>
;***** ...
cmp action_replay,2
jne pas_rec4

;******
;cmp economode,1
;je rertterterrtertytyrrtyrtyrtyrtyrtyrtyrty
;cmp economode,1
;je erererjhrejhreerlhehelej
cmp special_on_a_loadee_nivo,2 ;bizarrerie pour sortir a la fin du play
                               ;car on a fin un load mrb
jne rertterterrtertytyrrtyrtyrtyrtyrtyrtyrty
erererjhrejhreerlhehelej:
mov [sors_du_menu_aussitot],1
rertterterrtertytyrrtyrtyrtyrtyrtyrtyrty:
;*********

;total_play db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
;        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
;        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
;        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
;        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
;        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
;        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
;        db 0,0,0,00     ,0,0   ;8eme joeur d'un ordy
;        db 0,0


mov ebp,replayer_saver
;BIGENDIANPATCH ebp

xor ebx,ebx
lea esi,total_play

mov ecx,replayer_saver3

iencoermnjklrtrtytyuyuisdfgrht345:

;mov al,byte ptr fs:[1966080+TAILLE_HEADER_REC+TAILLE_BONUS_REC+ebp]


push esi
mov esi,replayer_saver4
mov al,byte ptr fs:[esi+TAILLE_HEADER_REC+TAILLE_BONUS_REC+ebp]
pop esi

mov byte ptr [esi+ebx],0
test al,0000001B
jz bhrebherterteeeeee
mov byte ptr [esi+ebx],1
bhrebherterteeeeee:
mov byte ptr [esi+ebx+1],0
test al,0000010B
jz bhrebherterteeeeeei
mov byte ptr [esi+ebx+1],1
bhrebherterteeeeeei:
mov byte ptr [esi+ebx+2],0
test al,0000100B
jz bhrebherterteeeeeeii
mov byte ptr [esi+ebx+2],1
bhrebherterteeeeeeii:
mov byte ptr [esi+ebx+3],0
test al,0001000B
jz bhrebherterteeeeeeiii
mov byte ptr [esi+ebx+3],1
bhrebherterteeeeeeiii:
mov byte ptr [esi+ebx+4],0
test al,0010000B
jz bhrebherterteeeeeeooo
mov byte ptr [esi+ebx+4],1
bhrebherterteeeeeeooo:
mov byte ptr [esi+ebx+5],0
test al,0100000B
jz bhrebherterteeeeeep
mov byte ptr [esi+ebx+5],1
bhrebherterteeeeeep:
mov byte ptr [esi+ebx+6],0
test al,01000000B
jz bhrebherterteeeeeept
mov byte ptr [esi+ebx+6],1
bhrebherterteeeeeept:

;xor ah,ah
;mov al,byte ptr [esi+5]
;shl al,5
;or ah,al
;mov al,byte ptr [esi+4]
;shl al,4
;or ah,al
;mov al,byte ptr [esi+3]
;shl al,3
;or ah,al
;mov al,byte ptr [esi+2]
;shl al,2
;or ah,al
;mov al,byte ptr [esi+1]
;shl al,1
;or ah,al
;mov al,byte ptr [esi]
;or ah,al
;mov byte ptr fs:[1966080+TAILLE_HEADER_REC+TAILLE_BONUS_REC+ebp],ah

inc ebp
add ebx,7

;cmp ebx,6*8
;
dec ecx
jnz iencoermnjklrtrtytyuyuisdfgrht345

;BIGENDIANPATCH ebp

mov replayer_saver,ebp

;----------- ;pour sortir si un slave press return... (euh en fait sil presse

;cmp temps_avant_demo,1
;je rertttttttttttttttttttttt345

touche_presse sortie 1
cmp sortie,1
jne rertttttttttttttttttttttt345
push eax
mov eax,ttp
mov temps_avant_demo,eax
pop eax
rertttttttttttttttttttttt345:
;-------

dec replayer_saver2

jnz continueeeee
;--
;cmp economode,2
;jne non_non_pas_en_mode_truc
;mov [sors_du_menu_aussitot],0
;mov economode,1
;non_non_pas_en_mode_truc:
;--


mov [sortie],1 ;on sort !
continueeeee:


;mov temps_avant_demo,ttp2
;----------


;control_joueur dd 8 dup (0) ;-1,6,32,32+6,-1,-1,-1,-1
;

;total_t db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
;        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
;        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
;        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
;        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
;        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
;        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
;        db 0,0,0,0     ,0,0   ;8eme joeur d'un ordy
;        db 0,0

pas_rec4:

POPALL
ret
endp

;affichage_rec proc near
;PUSHALL
;xor ax,ax
;mov al,byte ptr fs:[1966080+TAILLE_HEADER_REC]
;call affsigne
;mov al,byte ptr fs:[1966080+TAILLE_HEADER_REC+1]
;call affsigne
;mov al,byte ptr fs:[1966080+TAILLE_HEADER_REC+2]
;call affsigne
;mov eax,dword ptr fs:[1966080+TAILLE_HEADER_REC+TAILLE_BONUS_REC]
;call num
;xor eax,eax
;mov al,byte ptr fs:[1966080+TAILLE_HEADER_REC-1] ;1er octet: le numero du terrain
;call affsigne
;POPALL
;ret
;endp

load_gus proc near
PUSHALL

;BOOM     IFF        10,783  08-06-97  4:36a
;BANG     IFF         8,046  08-06-97 10:26a
;KLANNG   IFF         9,373  08-06-97 10:27a
;
;del iff.dat
;copy /B BOOM.IFF+BANG.IFF+KLANNG.IFF iff.Dat

mov edi,offset iff_liste
mov eax,[total_liste]
uencoremasuperdeliredemaker:
cmp dword ptr [edi],-1
je ufinitobabyr
add dword ptr eax,[edi]
mov dword ptr [edi],eax
add edi,4
jmp uencoremasuperdeliredemaker
ufinitobabyr:


       xor ebp,ebp
       mov eax,4

tyu:
        mov ecx,[iff_liste+ebp]
        cmp ecx,-1
        je ooo
        PUSHALL
      ;  call LOAD_BONUS_SAMPLE
        POPALL


        add ebp,4
        add eax,4
        jmp tyu
ooo:

;ECX: OFFSET
;! dans EaX NUMERO DU SAMPLE *4 !
;MOV BP,32*4

;mov byte ptr [BLOW_WHAT],8 ;8*4
;mov byte ptr [BLOW_WHAT+1],40

;mov byte ptr [BLOW_WHAT+12],2    ;8*4
;mov byte ptr [BLOW_WHAT+13],30

;mov byte ptr [BLOW_WHAT],073h ;4 bits:panning, 4 bits: sample
;mov byte ptr [BLOW_WHAT+1],40  ;0 droite. ici. F left


POPALL
ret
endp

init_packed_liste proc near
PUSHALL
mov edi,offset packed_liste
mov eax,taille_exe_gonfle
encoremasuperdeliredemaker:
cmp dword ptr [edi],-1
je finitobabyr
add dword ptr eax,[edi]
mov dword ptr [edi],eax
add edi,4
jmp encoremasuperdeliredemaker
finitobabyr:

mov [total_liste],eax

POPALL
 ret
init_packed_liste endp


menu proc near

PUSHALL

;regarde si le dernier packet est un packet de menu.. ou non...
; si c'est on est pas master...

;;cmp [master],1
;;jne erttrtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2r
;;
;;;cmp dword ptr [packed_data+1],'unem'
;;;je retttttttttttt
;;POPALL
;;ret


;retttttttttttt:

;erttrtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2r:

;       db 'menu' ;pout reconnaitre ou on est... enfin si c'est un packet


;sound_menu

;mov edi,896000+64000*3 ; 128000  ;307200

;---- affiche le PIC.PCX -----------------------------------------------
cmp [master],0
jne reerttrtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2R
cmp [pic_time],0
jz  reerttrtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2R

dec [pic_time]
cmp [pic_time],16
jne erterertyyuuutyutyutyutyutyutyutyuty
mov [affiche_pal],1
erterertyyuuutyutyutyutyutyutyutyuty:
cmp [pic_time],17         ;RE quitte pas pendant k'on efface la palette
jb erttertertertertert
cmp [pic_time],pic_max-34 ;quitte pas avant k'on ait la pallette affiché
ja erttertertertertert    ;
;cmp [last_sucker],0 ;derniere touche...
;je erttertertertertert
touche_presse pic_time 17
;mov [pic_time],17    ;accélere le processus...
erttertertertertert:

;cmp [assez_de_memoire],1
;je affiche_pas_


mov esi,896000+64000*1 ;896000+64000*3

;cmp kel_pic_intro,1
;jne opiopiioiouuiiuiuiuooorytyyryrtt
;mov esi,1966080+64000*21
;opiopiioiouuiiuiuiuooorytyyryrtt:

;===== affiche en ram video ce k'il y a a : FS:ESI
;      ENTREE : ESI
ramesi
;copyblock
copyblock
call aff_page2 ;affiche en ram video ce k'il y a a dans le buffer
;affiche_pas_:
POPALL
ret
reerttrtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2R:
;---------------------------------------------------------------------------

;cmp [assez_de_memoire],1
;je erettererttrtyrtyyrtrty

push es


cmp [last_sucker], 0
jne kjhkjhfhgfhgfhgfghfghfhgfhgfhgfhgfhgfghf

mov esi,896000+64000*3
;===== affiche en ram video ce k'il y a a : FS:ESI
;      ENTREE : ESI
mov esi,64000*4
ramesi
copyblock

kjhkjhfhgfhgfhgfghfghfhgfhgfhgfhgfhgfghf:

mov ax,ds
mov es,ax

;call copie_bande

;mov edi,offset buffer
;xor eax,eax
;mov ecx,16000
;rep stosD

call scroll

mov [viseur_couleur],0

;------ premiere barre.
;mov esi,64000*4+58*320
;mov edi,offset buffer
;push edi
;copie 80*71
;pop edi

;lea edi,buffer+(30*320+36*320+14+320*3+2)

lea edi,buffer+(30*320+36*320+14+320*3+2-06+2+320*08+1)
mov ebx,offset texte1
  mov ecx,4
  rrteertertrteert:
  PUSHALL
  ;---- edi: viseur sur ou ecrire
  ; ebx:texte
  ;------
  mov eax,[scrollyf]
  and eax,001100000B
  add ebx,eax
  call aff_texte
  POPALL
  add ebx,32*4

inc [viseur_couleur]

  add edi,80
  dec ecx
  jnz rrteertertrteert

;------ deuxieme barre.
;mov esi,64000*4+129*320
;mov edi,offset buffer+100*320
;push edi
;copie 80*71
;pop edi
;lea edi,buffer+(101*320+36*320+14+320*3+2)
lea edi,buffer+(101*320+36*320+14+320*3+2-06+2+320*08+1)
mov ebx,offset texte1+32*4*4

  mov ecx,4
  oorrteertertrteert:
  PUSHALL
  ;---- edi: viseur sur ou ecrire
  ; ebx:texte
  ;------
  mov eax,[scrollyf]
  and eax,001100000B
  add ebx,eax
  call aff_texte
  POPALL
  add ebx,32*4
inc [viseur_couleur]
  add edi,80
  dec ecx
  jnz oorrteertertrteert
;.............................................................................
pop es
call aff_page2 ;affiche en ram video ce k'il y a a dans le buffer
POPALL
ret
erettererttrtyrtyyrtrty:
;pas assez de mémoire...
POPALL
ret

aff_lettre:
push ecx
mov ecx,6
oertterertertertert:
push ebx

;couleur db 62,3,224,28,65,160,28,3
mov ebx,es:[viseur_couleur] ;db 0
cmp es:[ordre2],'Z'                    ; médaille distribution
jne rertetyutyuyuttuyyuttyu
mov bl,es:[couleur+ebx]
jmp rtyutyuyuttyutyuyutyutyut
rertetyutyuyuttuyyuttyu:
mov bl,es:[couleur_menu+ebx]
rtyutyuyuttyutyuyutyutyut:

crocro
crocro
crocro
crocro
crocro
crocro
crocro
crocro
pop ebx
add edi,320-8
add esi,320-8
dec ecx
jnz oertterertertertert
pop ecx
ret
aff_texte:

mov edx,3
reretertertrte:
mov ecx,6
ererrteertertertertert:
call affiche_un_caractere
add edi,8
dec ecx
jnz ererrteertertertertert
add edi,320*10-8*6
dec edx
jnz reretertertrte
ret
rerteertertertertertrteertertretrerertertert:
inc ebx
jmp rtrtytyryrtrtysepcialespace
affiche_un_caractere:
push edi ds
;mov esi,offset buffer3+165*320
mov esi,1582080+64000*5+165*320 ;offset buffer3
push fs
pop ds
;-- selectionne lettre
xor eax,eax
mov al,byte ptr es:[ebx]
cmp al,' '
je rerteertertertertertrteertertretrerertertert

cmp al,'z'+13 ;special pour le menu... espace dans nom d'un joueur...
je rerteertertertertertrteertertretrerertertert

cmp al,'?'
jne erttrerteertertertertertrteertertretrerertertertyyfr
;mov esi,223+171*320
mov esi,1582080+64000*5+232+8*3+172*320 ;[buffer3+232+8*3+172*320]
jmp reerertrteertertrteertrtertertrteert
erttrerteertertertertertrteertertretrerertertertyyfr:

;cmp al,'-'-'a'
;jne tderterterertZtr
;mov ax,304/8
;jmp rtrtyrtyrty
;tderterterertZtr:

cmp al,'-' ;curseur...
jne erttrerteertertertertertrteertertretrerertertertyyfrt
;mov esi,223+171*320
mov esi,1582080+64000*5+167*320+304 ;[buffer3+167*320+304]
sub edi,320*3
jmp reerertrteertertrteertrtertertrteert
erttrerteertertertertertrteertertretrerertertertyyfrt:

sub al,'a'
cmp al,'!'-'a'
jne erterterert
mov ax,288/8
jmp rtrtyrtyrty
erterterert:
cmp al,'.'-'a'
jne erterterertZ
mov ax,296/8
jmp rtrtyrtyrty
erterterertZ:

cmp al,':'-'a'
jne derterterertZ
mov ax,312/8
jmp rtrtyrtyrty
derterterertZ:

cmp al,'0'-'a'
jb rderterterertZ
add al,26-('0'-'a')
rderterterertZ:

rtrtyrtyrty:
shl ax,3

add esi,eax
reerertrteertertrteertrtertertrteert:
inc ebx
;----
call aff_lettre
rtrtytyryrtrtysepcialespace:
pop ds edi
ret
menu endp


scroll proc near

;---

inc [scrollyF]

;-- selectionne lettre
test dword ptr [scrollyF],0000000000111B
jnz trerteertertertertertrteertertretrerertertert
;223,171
xor eax,eax
mov ebx,offset tected

;-cmp [master],1
;-jne trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2R
;-mov ebx,offset tecte_sl
;-trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2R:
;-

add ebx,[tecte2]
inc [tecte2]
;tecte    db 'abcedfghijklmnopq remdy is back é'
;tecte2   dd 0


mov al,byte ptr [ebx]
cmp al,02ah
jne dtrerteertertertertertrteertertretrererterterte
lea edx,tected
sub edx,offset tecte
neg edx
mov [tecte2],edx
;lea esi,[buffer3+223+171*320]
mov esi,1582080+64000*5+223+171*320 ;64000*5+165*320 ;offset buffer3

jmp reerertrteertertrteert
dtrerteertertertertertrteertertretrererterterte:


mov al,byte ptr [ebx]
cmp al,0dbh
jne dtrerteertertertertertrteertertretrerertertert
;mov [tecte2],0
lea edx,tected
sub edx,offset tecte
neg edx
mov [tecte2],edx
mov esi,1582080+64000*5+223+171*320 ;[buffer3++223+171*320]

cmp [master],1
jne reerertrteertertrteert
mov [tecte2],0
jmp reerertrteertertrteert
dtrerteertertertertertrteertertretrerertertert:

cmp al,' '
jne erttrerteertertertertertrteertertretrerertertert
;mov esi,223+171*320
mov esi,1582080+64000*5+223+171*320 ;[buffer3+223+171*320]
jmp reerertrteertertrteert
erttrerteertertertertertrteertertretrerertertert:

cmp al,'/'
jne erttrerteertertertertertrteertertretrererterterty
;mov esi,223+171*320
;,ea esi,[buffer3+232+172*320]
mov esi,1582080+64000*5+223+172*320-8+16
jmp reerertrteertertrteert
erttrerteertertertertertrteertertretrererterterty:

cmp al,'('
jne erttrerteertertertertertrteertertretrerertertertyr
;mov esi,223+171*320
;,lea esi,[buffer3+232+8+172*320]
mov esi,1582080+64000*5+223+8+172*320-8+16
jmp reerertrteertertrteert
erttrerteertertertertertrteertertretrerertertertyr:

cmp al,')'
jne erttrerteertertertertertrteertertretrerertertertyy
;mov esi,223+171*320
;lea esi,[buffer3+232+8*2+172*320]
mov esi,1582080+64000*5+223+8*2+172*320-8+16
jmp reerertrteertertrteert
erttrerteertertertertertrteertertretrerertertertyy:

cmp al,'?'
jne erttrerteertertertertertrteertertretrerertertertyyf
;mov esi,223+171*320
;lea esi,[buffer3+232+8*3+172*320]
mov esi,1582080+64000*5+223+8*3+172*320-8+16
jmp reerertrteertertrteert
erttrerteertertertertertrteertertretrerertertertyyf:






sub al,'a'
cmp al,'!'-'a'
jne terterterert
mov ax,288/8
jmp trtrtyrtyrty
terterterert:
cmp al,'.'-'a'
jne terterterertZ
mov ax,296/8
jmp trtrtyrtyrty
terterterertZ:

cmp al,':'-'a'
jne tderterterertZ
mov ax,312/8
jmp trtrtyrtyrty
tderterterertZ:

cmp al,'-'-'a'
jne tderterterertZt
mov ax,304/8
jmp trtrtyrtyrty
tderterterertZt:


cmp al,'0'-'a'
jb trderterterertZ
add al,26-('0'-'a')
trderterterertZ:

trtrtyrtyrty:
shl ax,3

;inc ebx
;lea esi,[buffer3+165*320+eax]
mov esi,1582080+64000*5+165*320
add esi,eax
reerertrteertertrteert:
;----
;call aff_lettre

;:,:test [changement],0000111B
push ds
push fs
pop ds
mov edi,offset scrolly+320
mov ecx,6
frrr:
movsd
movsd
add edi,320
add esi,320-8
dec ecx
jnz frrr
pop ds

;---
trerteertertertertertrteertertretrerertertert:

lea esi,scrolly+1 ;   db 6*328 dup (01011101B)
lea edi,scrolly

mov ecx,328*6
rep movsb

lea esi,scrolly
mov edi,offset buffer+320*192
;4,5,6,7,8,9
mov edx,6
ddd:
mov ecx,320
;rep movsd
oooooooooi:
lodsb
or al,al
jz retertetyooo
mov es:[edi],al
retertetyooo:
inc edi
dec ecx
jnz oooooooooi

add esi,8

dec edx
jnz ddd
ret
endp


foo MACRO speed_bonus,i
local o2
cmp [last_bomb+i],eax
jne o2
cmp [vie+i],1 ;que les dyna vivants !!!!
jne  o2
cmp word ptr [speed_bonus+i],0 ;pas si deja une maladie..
jne o2
cmp word ptr [lapipipino2+i],1 ;check kangaroo jump
je o2
cmp word ptr [lapipipino2+i],2 ;check kangaroo jump
je o2
mov word ptr [speed_bonus+i],bx ;maladie..
mov word ptr [speed_bonus+i+2],duree_conta
o2:
ENDM

conta MACRO speed_bonus,ebp
local reterterrtertert
local o2
;last_bomb dd 8 dup (?)
;speed_bonus dd 8 dup (?)
cmp word ptr [speed_bonus+ebp],0 ;regarde si on a une maladie a donner.
je reterterrtertert
cmp [vie+ebp],1 ;que les dyna vivants !!!!
jne reterterrtertert

mov eax,[last_bomb+ebp]
;--- regarde pour les autres si
mov bx,word ptr [speed_bonus+ebp] ;dans bx on a la maladie...
foo maladie,0
foo maladie,4
foo maladie,8
foo maladie,12
foo maladie,0+16
foo maladie,4+16
foo maladie,8+16
foo maladie,12+16

reterterrtertert:
ENDM

decrem MACRO speed_bonus,o
local ertertrterteterrteert
local ooo
cmp word ptr [speed_bonus+o+2],0 ;255 ; dd 8 dup (?)
je ertertrterteterrteert
dec word ptr [speed_bonus+o+2]
jmp ooo
ertertrterteterrteert:
mov [speed_bonus+o],0 ;annule la maladie..
ooo:
ENDM

contamination proc near
PUSHALL

decrem  maladie,0
decrem  maladie,4
decrem  maladie,8
decrem  maladie,12
decrem  maladie,0+16
decrem  maladie,4+16
decrem  maladie,8+16
decrem  maladie,12+16

conta  maladie,0
conta  maladie,4
conta  maladie,8
conta  maladie,12
conta  maladie,0+16
conta  maladie,4+16
conta  maladie,8+16
conta  maladie,12+16

POPALL
ret
endp


;copie_bande proc near
;PUSHALL
;mov ebx,[machin2]
;
;dec dword ptr [changementZZ2] ;000011000B
;jnz retterertrte
;mov dword ptr [changementZZ2],time_bouboule ;011000B
;add [machin2],4
;cmp [machin2],4*29*2-4
;jne retterertrte
;mov [machin2],0
;retterertrte:
;
;mov esi,[machin+ebx]
;add esi,[machin3]
;
;push ds
;pop  es
;push fs
;pop ds
;add esi,896000+64000*4 ; 128000  ;307200
;lea edi,buffer
;mov edx,29
;ano:
;mov ecx,320/4
;rep movsd
;add esi,320
;dec edx
;jnz ano
;POPALL
;
;PUSHALL
;mov ebx,[machin2]
;sub ebx,4*29*2
;neg ebx
;dec dword ptr [changementZZ2] ;000011000B
;jnz retterertrtey
;;mov dword ptr [changementZZ2],time_bouboule ;011000B
;;add [machin2],4
;;cmp [machin2],4*29*2
;;jne retterertrtey
;;mov [machin2],0
;;retterertrtey:
;
;
;mov esi,[machin+ebx]
;add esi,[machin3]
;add esi,640*1
;push ds
;pop  es
;push fs
;pop ds
;add esi,896000+64000*4 ; 128000  ;307200
;lea edi,buffer+173*320
;mov edx,27
;anoy:
;mov ecx,320/4
;rep movsd
;add esi,320
;dec edx
;jnz anoy
;POPALL
;
;ret
;copie_bande endp

horloge proc near
PUSHALL

;inc es:[changementzz]
;

test [temps],01000000000000000B
jz clignote
;test dword ptr es:[changementzz],00000100000B
;jnz affiche_pas_deuxpointR
POPALL
ret
clignote:

;temps        dw 000200030000B  ;time
mov bp,temps

                ;1 bit, 3 bit,4 bits
;temps        db 10010001B  ;time

push ds
pop es
push fs
pop  ds
lea edi,buffer+320*183+277


push edi

xor eax,eax
mov ax,bp
shr ax,8
and ax,01111B
mov esi,896000+384000+46080+128000+83*320+80
shl eax,4
add esi,eax
SPRITE_16_11

mov esi,896000+384000+46080+128000+83*320+80+10*16
;lea edi,buffer+320*170+200+12

pop edi

push edi
add edi,12
test es:[temps],00100000000000000B
jnz affiche_pas_deuxpoint
SPRITE_16_5
affiche_pas_deuxpoint:

pop edi

;lea edi,buffer+320*170+200+12+6
push edi

add edi,12+6
xor eax,eax
mov ax,bp
shr ax,4
and ax,001111B
mov esi,896000+384000+46080+128000+83*320+80
shl eax,4
add esi,eax
SPRITE_16_11

pop edi
;,push edi
add edi,24+6
;lea edi,buffer+320*170+200+24+6
xor eax,eax
mov ax,bp
and ax,01111B
mov esi,896000+384000+46080+128000+83*320+80
shl eax,4
add esi,eax
SPRITE_16_11

POPALL
ret
endp
gestion_bdraw proc near

;test temps,000111111111111B
;jnz zerrezrezezrerrteerzerooo
;cmp in_the_apocalypse,0
;jne zerrezrezezrerrteerzerooo
;mov balance_le_bdrawn,1
;zerrezrezezrerrteerzerooo:

cmp balance_le_bdrawn,0
jne ereretereterreer233
ret
ereretereterreer233:

PUSHALL
;mov bdraw666,'03'
;mov bdraw1,60

;cas particulier... on est entré en phase 1 seul dyna vivant...
;on doit donc arreter le compte a rebourd...

cmp [attente_avant_med],attente_avant_med2
jne ertertertertetrertertertzet
;--

cmp word ptr bdraw666,'99'
je kjmlkjjkmlkjlmjklmjmkl
dec bdraw1
jnz kjmlkjjkmlkjlmjklmjmkl
mov bdraw1,60
dec bdraw666+1
cmp bdraw666+1,'0'-1
jne kjmlkjjkmlkjlmjklmjmkl
mov bdraw666+1,'9'
dec bdraw666
cmp bdraw666,'0'-1
jne kjmlkjjkmlkjlmjklmjmkl
mov bdraw666,'9'
kjmlkjjkmlkjlmjklmjmkl:

cmp adder_bdraw,0
je ertertertertetrertertertzet
cmp nombre_de_dyna,1
je ertertertertetrertertertzet
sub adder_bdraw,320
ertertertertetrertertertzet:
;--------------
POPALL
ret
endp

dec_temps proc near
PUSHALL

test temps,000111111111111B
jz zerooo
;mov balance_le_bdrawn,0
cmp temps2,15
jne nonononoiuioiohjrr

;--- deuxieme cas particulier-
cmp special_clignotement,0
je dommage_pp
dec special_clignotement
jmp special_fete
dommage_pp:
;-----------------------------
or  temps,00100000000000000B
mov ax,temps
and ax,0011111111111111B
cmp ax,000010001B
ja nonononoiuioiohjrr
special_fete:
or  temps,01000000000000000B ;clinotement général.
nonononoiuioiohjrr:

cmp temps2,1
jne nonononoiuioiohjrrt
and  temps,01011111111111111B
test temps,01000000000000000B
jz nonononoiuioiohjrrt
bruit3 6,40,BLOW_WHAT2
and  temps,00111111111111111B ;glonotement global..
nonononoiuioiohjrrt:

dec temps2
jz ertterrtyrtyrtyyrt
POPALL
ret
zerooo:
;-*-*-*-*-*-*-*-*-*-*- apocalypse

cmp terrain,6
jne ertrtytyuyuiiyuughfdfgdfgfgdrtyrtyrtyerertertert
call pose_une_bombe_bonus
ertrtytyuyuiiyuughfdfgdfgfgdrtyrtyrtyerertertert:
;--------


;test dword ptr [changement],0000000000001B
;jnz finto_pasé_cetelmk

;133: virrer la brique. pour le milieu...

;test temps,000111111111111B
;jz zerooo
;
mov in_the_apocalypse,0

push ds
pop  es
lea esi,truc_fin
lea edi,truc
mov ecx,32*13
nextooi:
cmp byte ptr [esi],0
je nextooo

mov in_the_apocalypse,1                 ;indiquate the apocalypse is going on

;test temps,000111111111111B
;jz zerooo
;mov balance_le_bdrawn,0


;------------- vitesse de l'apocalypse... ---
mov eax,dword ptr [truc_fin+32*13] ;recup la vitesse.
test [changement],eax
jnz nextooo
  dec byte ptr [esi]

  ;quand arrive a 133 defonce ce kil y avait en dessous...
  ;mais ne posera pas de brike dure, puisuquon aurra mis byte ptr [esi] a 0
  ;malin...

  ;------ cas particulier... anti-brique... (et au milieu...)
  cmp byte ptr [esi],133
  jne nextooo567888888_
    mov special_nivo_6,60 ;indike de pas filler de bonus :) (cf. nivo 6)

  ;TOFIX    cmp terrain,6 ;terrain nivo 6
  ;TOFIX    je ertrtytyuyuiiyuughfdfgdfgfgdrtyrtyrtyertetttrrttrt
      mov balance_le_bdrawn,1 ;indique de balancer es 30 dernieres secondes
      ertrtytyuyuiiyuughfdfgdfgfgdrtyrtyrtyertetttrrttrt:

    cmp byte ptr [edi],2 ;pour brique.
    jne nextoooy
    ;194

      ;----- explosion de la brike ---
      cmp terrain,6 ;terrain nivo 6
      je ertrtytyuyuiiyuughfdfgdfgfgdrtyrtyrty
      mov byte ptr [edi],0         ;+degages la brique
      mov byte ptr [edi+32*13],194 ;+ explosion
      bruit3 4,40,BLOW_WHAT2
      jmp nextoooy
      ;------ cas particulier: nivo 6: brike se decompose
      ertrtytyuyuiiyuughfdfgdfgfgdrtyrtyrty:
      mov byte ptr [edi],3 ;casse la brique... normallement
      nextoooy:
    mov byte ptr [esi],0
    jmp nextooo
  nextooo567888888_:

  ;---------- endroit normal.. bombardement de piece dure.
  cmp byte ptr [esi],0
  jne nextooo
  cmp byte ptr [edi],1 ;si y'en a deja une...
  je nextooo
  ;194
  ;bruit2 4 40
  mov byte ptr [edi],11        ;place la brique dure.
  mov byte ptr [edi+32*13],194 ;+ explosion
  bruit2 4,40
nextooo:

inc edi
inc esi
dec ecx
jnz nextooi
finto_pas_cetelmk:
POPALL
ret
;*--*-*-*-*-*-*-*-* décrémentation du compte  rebour.
ertterrtyrtyrtyyrt:

mov temps2,59
;--------
mov ax,temps
and ax,01111B
dec ax
cmp ax,-1
jne pas_zeroret
mov ax,9
jmp canal_sux
pas_zeroret:
and temps,01111111111110000B
or temps,ax
POPALL
ret
canal_sux:
and temps,01111111111110000B
or temps,ax

mov ax,temps
shr ax,4
and ax,01111B
;mov bl,al
dec ax
cmp ax,-1
jne pas_zeroret7
mov ax,5
jmp stade
pas_zeroret7:
shl ax,4
and temps,01111111100001111B
or temps,ax
POPALL
ret
stade:
shl ax,4
and temps,01111111100001111B
or temps,ax

mov ax,temps
shr ax,8
;and ax,01111B
;mov bl,al
dec ax
cmp ax,-1
jne pas_zeroret72
mov ax,9
jmp stade
pas_zeroret72:
shl ax,8
and temps,01111000011111111B
or temps,ax

POPALL
ret
endp

gestion_blanchiment proc near
PUSHALL
xor ebp,ebp
verite:
mov eax,0
cmp [invinsible+ebp],0
je bababh
dec dword ptr [invinsible+ebp]
mov ax, word ptr [invinsible+ebp]
and eax, 1023
mov al,[blinking+eax]
and eax, 1
bababh:
mov [clignotement+ebp],eax

add ebp,4
cmp ebp,4*8
jne verite
POPALL
ret
endp
nike_toutes_ses_bombes proc near ;entree ebx: viseur infojoueur.
PUSHALL
mov ecx,[liste_bombe]
or ecx,ecx
jz upasdutout
lea esi,liste_bombe+4-taille_dune_info_bombe
unext_bomby:
add esi,taille_dune_info_bombe
cmp dword ptr [esi+4],0
jne uya_bombe_ici
jmp unext_bomby
uya_bombe_ici:
;------- unqieuemnt si c'est notre propre bombe...
cmp dword ptr [esi],ebx
jne unon_dejar
;--------- uniquement si cette bombe etait a retardement...
cmp word ptr [esi+4*3+2],1
jne unon_dejar
mov word ptr [esi+4*3+2],2 ;la rend preske normalle .... ;0 ;le rend normalle
unon_dejar:
dec ecx
jnz unext_bomby
upasdutout:
POPALL
ret
endp

nike_toutes_les_bombes proc near
PUSHALL
mov ecx,[liste_bombe]
or ecx,ecx
jz upasdutoutu
lea esi,liste_bombe+4-taille_dune_info_bombe
unext_bombyu:
add esi,taille_dune_info_bombe
cmp dword ptr [esi+4],0
jne uya_bombe_iciu
jmp unext_bombyu
uya_bombe_iciu:
;--------- uniquement si cette bombe etait a retardement...
mov word ptr [esi+4*3+2],0 ;le rend normalle
mov dword ptr [esi+1*4],1
dec ecx
jnz unext_bombyu
upasdutoutu:
POPALL
ret
endp

pousse_la_bombe proc near
PUSHALL
;cmp byte ptr [esi+32*13],1
;jb efrerrereterter
;cmp byte ptr [esi+32*13],4
;ja efrerrereterter
;--- ya une bombe !!! essaye de la pousser ---
;
;call pouse_la_bombe
sub esi,offset truc

;recherche cette bombe.
xor ebx,ebx
ttyrrtyrtyrtyrtytyrrtyrtyyrtrtye:
cmp dword ptr [liste_bombe+ebx+4+1*4],0 ;indique emplacement non remplis !!!
je cherche_encore
cmp dword ptr [liste_bombe+ebx+4+2*4],esi ;regarde si ya une bombe a cet endroit
jne cherche_encore
jmp okey_on_puse
cherche_encore:
add ebx,taille_dune_info_bombe
jmp ttyrrtyrtyrtyrtytyrrtyrtyyrtrtye
okey_on_puse:

;mov dword ptr [liste_bombe+ebx+4+1*4],1
;
;on peut pousser ke si elle est au milieu
cmp word ptr [liste_bombe+ebx+4+5*4],0    ; adder X
jne peu_pas_pousser                       ;
cmp word ptr [liste_bombe+ebx+4+5*4+2],0  ;adder Y
jne peu_pas_pousser

;---- cas particulier -- on ne pousse pas vers le bas en bas ----
;cas particulier speical cote rebondissant pour eviter kon fasse rebondir
;contre un mur alors ke la bombe y est colle.
;bas
cmp esi,32*11
jb pas_ce_cas_larrr
cmp ecx,2
je peu_pas_pousser
pas_ce_cas_larrr:
;haut
cmp esi,32*2
jnb pas_ce_cas_larrr2
cmp ecx,2
je peu_pas_pousser
pas_ce_cas_larrr2:

and esi,31
;gauche
cmp esi,1
jne pas_ce_cas3
or ecx,ecx
jz peu_pas_pousser
pas_ce_cas3:

;droite
cmp esi,17
jne pas_ce_cas5
or ecx,ecx
jz peu_pas_pousser
pas_ce_cas5:
;----------------------------------------------------

mov dword ptr [liste_bombe+ebx+4+4*4],0    ;pour degager l'ancien mouvement
                                           ;si elle bougait
                                           ;deja...
add ebx,ecx ;!!!!!!!!!!!!                  ;oU y automatique cA dEPENT dE eCX
mov word ptr [liste_bombe+ebx+4+4*4],ax ;0 ;!!!!!!!!!1 ;adder X automatique.

bruit2 13,34

peu_pas_pousser:
;mov word ptr [liste_bombe+ebx+4+4*4+2],0
;mov word ptr [liste_bombe+ebx+4+5*4],15   ;adder X
;mov word ptr [liste_bombe+ebx+4+5*4+2],0 ;adder Y
POPALL
ret
endp

;truc_monstre db 32*13 dup (?)
fabrique_monstro_truc proc near
PUSHALL
push ds
pop es
lea edi,truc_monstre
xor eax,eax
mov ecx,32*13/4
rep stosd

xor ebp,ebp
zecompetion:
cmp [vie+ebp],1
jne  fdggrtetyrklmjyurtmkljrtymjklyut

push ebp
xy_to_offset
mov [truc_monstre+eax],''
pop ebp
fdggrtetyrklmjyurtmkljrtymjklyut:
add ebp,4
cmp ebp,8*4
jne zecompetion

POPALL
ret
endp


pose_une_bombe_bonus proc near
PUSHALL
;call noping
;liste_bombbbb dd 32+1
;              dd 32*3+1
;              dd 32*5+1
;              dd 32*7+1
;              dd 32*9+1
;
cmp [attente_avant_med],attente_avant_med2
jne errteerterttyjtyutyuutytyuyutyutyututy

;test dword ptr [changement],0000000000111B
;jnz errteerterttyjtyutyuutytyuyutyutyututy
;

cmp attente_entre_chake_bombe,0
je okokokokok_cette_fois
dec attente_entre_chake_bombe
jmp errteerterttyjtyutyuutytyuyutyutyututy
okokokokok_cette_fois:

add viseur__nouvelle_attente_entre_chake_bombe,4

;nouvelle_attente_entre_chake_bombe2 dd 16,21,17,9,20,15,12,20
lea esi,nouvelle_attente_entre_chake_bombe2
add esi,viseur__nouvelle_attente_entre_chake_bombe
cmp esi,offset viseur__nouvelle_attente_entre_chake_bombe
jne ertteertertertertter
cmp [acceleration],20
je retteterrterteterertert
inc [acceleration]
retteterrterteterertert:
mov viseur__nouvelle_attente_entre_chake_bombe,0
lea esi,nouvelle_attente_entre_chake_bombe2
ertteertertertertter:

mov ebx,[esi]
sub ebx,[acceleration]
js loupe
jz loupe
jmp rrtyertyrtyrtyrtyertyrtytyr
loupe:
mov ebx,1
rrtyertyrtyrtyrtyertyrtytyr:
mov attente_entre_chake_bombe,ebx


mov ebx,liste_bombbbb2
add ebx,12
lea esi,liste_bombbbb+ebx
cmp esi,offset liste_bombbbb2
;
;cmp ebx,4*6
jne e6rtertertert
xor ebx,ebx
e6rtertertert:
mov liste_bombbbb2,ebx
mov eax,[liste_bombbbb+ebx]
mov dx,word ptr [liste_bombbbb+4+ebx]
mov cx,word ptr [liste_bombbbb+6+ebx]
mov ebp,dword ptr [liste_bombbbb+8+ebx]
lea esi,truc2
;mov eax,32*1+1
add esi,eax

cmp byte ptr [esi-32*13],0 ;regarde si ya rien ou l'on veut placer la bombe
jne  ytreteterrterteterertter
cmp byte ptr [esi],0 ;regarde si ya rien ou l'on veut placer la bombe
jne  ytreteterrterteterertter

;cmp cx,-1
;jne retterertertertter
;sub esi,2
;retterertertertter:
;inc esi
;cmp byte ptr [esi-32*13],0 ;regarde si ya rien ou l'on veut placer la bombe
;jne  ytreteterrterteterertter
;cmp byte ptr [esi-32*13],0 ;regarde si ya rien ou l'on veut placer la bombe
;jne  ytreteterrterteterertter
;cmp byte ptr [esi],0 ;regarde si ya rien ou l'on veut placer la bombe
;jne  ytreteterrterteterertter
;cmp cx,-1
;jne rettererterterttere
;add esi,2
;rettererterterttere:
;dec esi

mov byte ptr [esi],1

;dec dword ptr [edi] ;nombre de bombes k'on peut encore poser...

;donnee dw 20,20,277,277,150,200,250,280  ;x du dynablaster
;       dw 9,170,9,170,78,98,98,10 ;y du dynablaster

;liste_bombe dd 0 ; nombre de bombes...
;            dd 247 dup (0,0,0,0)
;1er: offset de l'infojoeur
;2eme: nombre de tours avant que ca PETE !!! ; si = 0 ca veut dire
;                                            ;emplacement libre...
;3eme:distance par rapport au debut de truc2
;4eme:DD= 1 DW: puissance de la bombe + 1 DW: bombe a retardement ??? (=1)
;5eme: VITESSE:1 db:X (+1/-1/0) ,1 db:Y (+1/-1/0);+ 2 db VIDE
;6eme: ADDER_X/Y: 1 dw:X,1 dW:Y


;mov ebx,[liste_bombe]
;shl ebx,4 ;*16

;recherche la premiere place de libre !!!
xor ebx,ebx
yttyrrtyrtyrtyrtytyrrtyrtyyrtrty:
cmp dword ptr [liste_bombe+ebx+4+1*4],0 ;indique emplacement non remplis !!!
je yerertertrteterert
add ebx,taille_dune_info_bombe
jmp yttyrrtyrtyrtyrtytyrrtyrtyyrtrty
yerertertrteterert:

;mov edx,3 ;dword ptr [edi+4]        ;récupere la puissance de la bombe dans
                                 ;l'info du joueur...
;mov ecx,256 ;dword ptr [edi+8]        ;récupere la taille de la meiche de la
                                 ;bombe dans l'info du joueur...

;------------------------------------ mouvement de la bombe


;push dx
;  cmp dx,-7
;  jne zerertrterteterert
;  mov dl,-7
;  zerertrterteterert:
  mov byte ptr [truc_X+eax],dl  ;;;;;;;;;;;;;;;;;;;;;;;;;;dl ;0
;pop dx

mov byte ptr [truc_Y+eax],0

mov [liste_bombe+ebx+4+0*4],offset infojoueur2
mov [liste_bombe+ebx+4+1*4],ebp ;ecx  ;nombre de tours avant que ca PETE !!!
mov [liste_bombe+ebx+4+2*4],eax  ;distance par rapport au debut de truc2
mov word ptr [liste_bombe+ebx+4+3*4],3 ;dx  ;puissance de la bombe.
mov word ptr [liste_bombe+ebx+4+3*4+2],0 ;dx  ;bombe a retardement ou pas ???
mov word ptr [liste_bombe+ebx+4+4*4],cx ;adder X automatique.
mov word ptr [liste_bombe+ebx+4+4*4+2],0
mov word ptr [liste_bombe+ebx+4+5*4],dx ;-7 ;0   ;adder X
mov word ptr [liste_bombe+ebx+4+5*4+2],0 ;adder Y

;5eme: VITESSE:1 db:X (+1/-1/0) ,1 db:Y (+1/-1/0);+ 2 db VIDE
;6eme: ADDER_X/Y: 1 dw:X,1 dW:Y


;edi  ;offset de l'infojoeur
inc dword ptr [liste_bombe]
ytreteterrterteterertter:
errteerterttyjtyutyuutytyuyutyutyututy:
POPALL
ret
endp

calc_ombres proc near
PUSHALL
;
;call noping
;call noping
;call noping
;donnee       dw 8 dup (?) ;x du dynablaster
;             dw 8 dup (?) ;y du dynablaster
xor ebx,ebx
xor ebp,ebp
mov kel_ombre,0
mertrymrtejklertyjklmtyer:

cmp [lapipipino+ebp],0
je pas_un_lapin_345
;cmp [lapipipino5+ebp],0
;je pas_un_lapin_345 ;ki saute pas
mov eax,1
cmp [lapipipino5+ebp],6
jb aaaaaa
mov eax,2
aaaaaa:
cmp [lapipipino5+ebp],12
jb aaaaaa2
mov eax,3
aaaaaa2:

;mort de lapin
cmp [lapipipino2+ebp],3 ;mort du lapin
jne veuoooooooooooi
mov eax,4
cmp [lapipipino3+ebp],27
ja reeeeeeeeeet
inc eax
cmp [lapipipino3+ebp],24
ja reeeeeeeeeet
inc eax
cmp [lapipipino3+ebp],21
ja reeeeeeeeeet
inc eax
cmp [lapipipino3+ebp],18
ja reeeeeeeeeet
inc eax
cmp [lapipipino3+ebp],16
ja reeeeeeeeeet
inc eax
cmp [lapipipino3+ebp],14
ja reeeeeeeeeet
inc eax
cmp [lapipipino3+ebp],11
ja reeeeeeeeeet
inc eax
cmp [lapipipino3+ebp],08
ja reeeeeeeeeet
inc eax
cmp [lapipipino3+ebp],05
ja reeeeeeeeeet
inc eax
reeeeeeeeeet:

mov ecx,ebp
shl eax,cl
or [kel_ombre],eax
xor eax,eax
mov ax,[donnee+8*2+ebx]
add ax,15
EAX_X_320
add ax,[donnee+ebx]
add ax,4
sub ax,8
sub ax,320*19
mov [ombres+ebx],ax


jmp pas_un_lapin_345
veuoooooooooooi:
;-----

mov ecx,ebp
shl eax,cl
or [kel_ombre],eax
xor eax,eax
mov ax,[donnee+8*2+ebx]
add ax,15
EAX_X_320
add ax,[donnee+ebx]
add ax,4
mov [ombres+ebx],ax

pas_un_lapin_345:
add ebp,4
add ebx,2
cmp ebx,2*8
jne mertrymrtejklertyjklmtyer


POPALL
ret
endp

aff_ombres proc near
PUSHALL

;--- pour ombres ---
;kel_ombre   dd 0
;ombres      dw 8 dup (?)
;-------------------
mov esi,1582080+64000*5 ;offset buffer3
;add esi,ebx
;push ds
xor ebp,ebp
mov edi,offset buffer

push fs
pop ds

xor ebp,ebp
xor ebx,ebx
rtmklmrtyjklrtymjkrtyjklmrtyrty:

mov eax,1111B
mov ecx,ebp
shl eax,cl
mov edx,es:[kel_ombre]
and edx,eax
shr edx,cl

or  edx,edx
jz nananan_pas_dombre_ici

push esi edi ebx
cmp edx,2
jne oooooorytrtyrtyp
add esi,24
oooooorytrtyrtyp:
cmp edx,3
jne oooooorytrtyrtyp4
add esi,24*2
oooooorytrtyrtyp4:

;mort phase 1 (carcasse de lapin mort. hey oui c une ombre)
cmp edx,4
jb caaaaaaaaaaaaaaaaa
mov esi,1966080+64000*8+1+1*320
;---- couleur rose ou bleu
test ebp,0100B
jnz c_une_fille
add esi,320*(33+33)
c_une_fille:
;-----

sub edx,4
shl edx,5                 ;*32
add esi,edx
xor eax,eax
mov ax,es:[ombres+ebx]
add edi,eax
SPRITE_32_32
pop ebx edi esi
jmp nananan_pas_dombre_ici
caaaaaaaaaaaaaaaaa:

xor eax,eax
mov ax,es:[ombres+ebx]
add edi,eax
add esi,71+150*320
;aff_omb
SPRITE_8_16
pop ebx edi esi

nananan_pas_dombre_ici:

add ebx,2
add ebp,4
cmp ebx,8*2
jne rtmklmrtyjklrtymjkrtyjklmrtyrty

POPALL
ret
endp

deplacement_bombes proc near

poussage 1,0,1
poussage -1,0,1
poussage 1,2,32
poussage -1,2,32
poussage 1,0,1
poussage -1,0,1
poussage 1,2,32
poussage -1,2,32

ret
endp


compact proc near
ret
endp

decompact proc near
ret
endp

zget_information proc near
ret
endp

ferme_socket proc near
ret
endp



;; fin include

;ééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééé
; CODE
;ééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééé

;ééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééé
; Entry To ASM Code (_main)
; In:
;   CS - Code Selector    Base: 00000000h - Limit: 4G
;   DS - Data Selector    Base: 00000000h - Limit: 4G
;   ES - PSP Selector     Base: PSP Seg   - Limit: 100h   ;segment video: selector: ES
;   FS - ?
;   GS - ? ;sauvegarde de DS..
;   SS - Data Selector    Base: 00000000h - Limit: 4G
;   ESP -> STACK segment
;   Direction Flag - ?
;   Interrupt Flag - ?
;
;   All Other Registers Are Undefined!
;ééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééé
_main:
        sti                             ; Set The Interrupt Flag
        cld                             ; Clear The Direction Flag




        PUSHALL



;PUSHALL

; protected mode shit ?
;mov ah,02ch
;int 21h

;xor eax,eax
;mov al,dh
;and eax,11100B
;mov differentesply2,eax

;and dh,01
;mov kel_pic_intro,dh

;POPALL



 ;       mov ax,3h
 ;       int 10h

mov eax,ttp
mov temps_avant_demo,eax

        call doStuffClavierExtended


        POPALL

        ;----- inst clavier -
        PUSHALL
        xor eax,eax
        mov ax,ds
mov ss:[merdo],eax     ;IGNORE
        call inst_clavier
        POPALL
        ;---

 ;       push    0h
 ;       call    GetModuleHandleA
 ;       mov     [AppHWnd],eax
 ;       call    GetForegroundWindow
 ;       push    3
 ;
; this can be any of the following values :
;SW_HIDE                         equ      0
;SW_SHOWNORMAL                   equ      1
;SW_NORMAL                       equ      1
;SW_SHOWMINIMIZED                equ      2
;SW_SHOWMAXIMIZED                equ      3
;SW_MAXIMIZE                     equ      3
;SW_SHOWNOACTIVATE               equ      4
;SW_SHOW                         equ      5
;SW_MINIMIZE                     equ      6
;SW_SHOWMINNOACTIVE              equ      7
;SW_SHOWNA                       equ      8
;SW_RESTORE                      equ      9
;SW_SHOWDEFAULT                  equ     10
;SW_MAX                          equ     10

;        push    eax
;        call    ShowWindow

;          CALL    ExitProcess     ;End (exit) program
;        call get_pal_ansi


        PUSHALL
;        mov bp,240h

;setup_viseur dd 0
;setup_viseur2 dd 8
;setup_viseur2_offset dw 210h,220h,230h,240h,250h,260h,270h,280h,0

;cmp economode,1
;jne trreljljrjkltjhtehljtehljte
;mov setup_viseur2,8
;trreljljrjkltjhtehljtehljte:

;mov ebx,setup_viseur2
;add ebx,ebx
;xor ebp,ebp
;mov bp,[setup_viseur2_offset+ebx]
;mov bp,260h
;mov ax,bp
;call affsigne
;setup_viseur2_offset dw 210h,220h,230h,240h,250h,260h,270h,280h,0

      ; REMOVED  call detect ;es:PSP
        POPALL

        ;mov ax,4c00h                    ; AH=4Ch - Exit To DOS
        ;int 21h                         ; DOS INT 21h

;reserve la memoire pour les données --> selector: FS
                    ;segment video: selector: ES

                    
;1966080
taille_moire equ ((((2030080+64000*26)/4096)+1)*4096)-1

;--------------------- r�serve de la m�moire pour mettre les donn�es. ----
;2.29 - Function 0501h - Allocate Memory Block:
;In:  AX     = 0501h
;  BX:CX  = size of block in bytes (must be non-zero)
;Out: if successful:
;    carry flag clear
;    BX:CX  = linear address of allocated memory block
;    SI:DI  = memory block handle (used to resize and free block)
mov eax,taille_moire
;0200000h ;2mega
mov cx,ax
shr eax,16
mov bx,ax
mov ax,501h
int 31h
jNC ca_roule_roll

;mov edx,offset pas_de_mem
;mov ah,9
;int 21h

; !!!!!! RETIRE mov [assez_de_memoire],1  ; db 0  ; 0 OUI suffisament
nanananaaaaaaaaaaaa_demande_ligne_c:
jmp okokokokokoioioiioio
ca_roule_roll:

push bx cx ; linear address of allocated memory block

;2.0 - Function 0000h - Allocate Descriptors:
;--------------------------------------------
;  Allocates one or more descriptors in the client's descriptor table. The
;descriptor(s) allocated must be initialized by the application with other
;function calls.
;In:
;  AX     = 0000h
;  CX     = number of descriptors to allocate
;Out:
;  if successful:
;    carry flag clear
;    AX     = base selector
xor ax,ax
mov cx,1
int 31h
jNC ca_roule_roll2
;mov edx,offset pbs1
;mov ah,9
;int 21h
mov ax,4c00h                    ; AH=4Ch - Exit To DOS
int 21h                         ; DOS INT 21h
ca_roule_roll2:
;2.5 - Function 0007h - Set Segment Base Address:
; Sets the 32bit linear base address field in the descriptor for the specified
;segment.
; In:   AX     = 0007h
; BX     = selector
;  CX:DX  = 32bit linear base address of segment

pop  dx cx ; linear address of allocated memory block
mov  bx,ax
mov  fs,ax
mov ax,0007
;mov cx,si //removed???
;mov dx,di // Removed???

int 31h
;dans FS: selector sur donn�es.

;2.6 - Function 0008h - Set Segment Limit:
;-----------------------------------------
;  Sets the limit field in the descriptor for the specified segment.
;  In:
;  AX     = 0008h
;  BX     = selector
;  CX:DX  = 32bit segment limit
;  Out:
;  if successful:
;    carry flag clear
;  if failed:
;    carry flag set
mov eax,taille_moire  ;::!300000h-1 ;182400h-1 ;1582080 ;0300000h-1 ;2mega 182400h-1
;mov eax,((((2582080)/4096)+1)*4096)-1  ;::!300000h-1 ;182400h-1 ;1582080 ;0300000h-1 ;2mega 182400h-1

mov dx,ax
shr eax,16
mov cx,ax
mov bx,fs
mov ax,08h
int 31h
jNC tca_roule_roll
;mov edx,offset pbs2
;mov ah,9
;int 21h
mov ax,4c00h                    ; AH=4Ch - Exit To DOS
int 21h                         ; DOS INT 21h
tca_roule_roll:

;-------------------------------------------------------------------------

;----- pour la memoire video
mov ax,0002h
mov BX,0a000h
int 31h
mov es,ax

okokokokokoioioiioio:


;        mov ax,4c00h                    ; AH=4Ch - Exit To DOS
;        int 21h                         ; DOS INT 21h


;        mov ax,4c00h                    ; AH=4Ch - Exit To DOS
;        int 21h                         ; DOS INT 21h


      ; mov ax,4c00h                    ; AH=4Ch - Exit To DOS
      ; int 21h

call init_packed_liste










cmp modeinfo,1            ;cas ou on scan le reso.
jne ertrerertrtrer
call zget_information
ertrerertrtrer:

;-*-*-*-*-*===================_____X____)\_,--------------------------

;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*


call load_data ;serra fait que si y'a assez de memoire.

; PASSE EN MODE  13h!!!
        mov ax,13h
        int 10h
        call affpal

;lea esi,pal_pic2
;PUSHALL
;push ds
;pop es
;
;lea esi,pal_pic2 ;;;rene
;lea edi,pal_affichée
;mov ecx,768
;rep movsb
;pal          db  768 dup (?)  ;pal  de l'émulateur.
;pal_affichée db 768 dup (0)   ;pal k'on affiche...
;POPALL
;mov esi,1966080+64000*21
;copyblock
;call aff_page2


;cmp [assez_de_memoire],1
;
;        je eretterertd
;        call affpal
;eretterertd:



hoooooooop:
call init_menu
reterrterterte:
call menu
call pal_visage
;call play_fx
call controle

;gestion temps de demo/repousse le compte a rebours
;cmp temps_avant_demo,1
;je ljljrtjhrljhrryr
touche_pressedd temps_avant_demo ttp
;ljljrtjhrljhrryr:
;==================== SPECIAL DEMO,pour kitter avec nimporte kelle touche...
cmp action_replay,2
jne erterertrtertetertyutyuyuttyuuty
cmp nombre_de_vbl_avant_le_droit_de_poser_bombe,0 ;pas des le debut...
jne erterertrtertetertyutyuyuttyuuty
touche_presse sortie 1
erterertrtertetertyutyuyuttyuuty:
;=================================================================


;kb_packets_jeu_envoyes dd 0

;call gooroo
;return_presse demande_partie_slave,1
mov nosetjmp,1
vbl
directmenu:
call menu_intelligence
get_all_infos3         ; récupere les touches pour chaque joueur et pour
                       ; tous les différents ordinateurs.

mov on_les_dans_le_menu,1
;call master_net

;--- esc du master ---------------------------------

cmp sors_du_menu_aussitot,1
jne y_special_mrb
mov byte ptr [sortie],1 ;eSC.
y_special_mrb:

cmp byte ptr [sortie],1 ;eSC.
jne erertrterteertrteertertrtertertyeertrteertterertertterertterert
mov byte ptr [sortie],0 ;// ignore...


;;mov [previentlmesenfants],1
;cmp byte ptr [ordre],'B' ;pour bye... (du master)
;je rtertertyeertrteertterertertterertterert
;mov byte ptr [ordre],'B' ;pour bye...
;jmp reterrterterte


erertrterteertrteertertrtertertyeertrteertterertertterertterert:
;----------------------------------------------------------------------

;cmp changement,300
;jne poiy
;mov byte ptr [sortie],1 ;eSC. ;!!!!!!!!
;poiy:

;cmp byte ptr [ordre],'B' ;pour bye... (du slave)
;jne rtertertyeertrteertterertertterertterert2RT
;mov previentlmesenfants,1 ;pour slave: affiche messgae fin
;jmp rtertertyeertrteertterertertterertterert
;rtertertyeertrteertterertertterertterert2RT:

cmp [attente_nouveau_esc],0
jne ook

cmp [master],0
jne oook2
cmp byte ptr [sortie],1 ;eSC.
je rtertertyeertrteertterertertterertterert
jmp oook2
ook:
dec [attente_nouveau_esc]
oook2:

cmp byte ptr [ordre],''
jne reterrterterte
;--------------------------------------------------------------------
nouvelle_partie345:

call nouvelle_partie

nouvelle_manche3:

call nouvelle_manche

;**************************************************************************
retertdgrfgd:

call pal_visage

;call play_fx

;----- gestion des joeurs locaux.

call controle    ;prépare le packet qu'on va transmettre en informant
                 ;les touches ke l'on presse actuellement

;*************************** MASTER *******************************
cmp [master],0
jne trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty
;call gooroo
mov on_les_dans_le_menu,0
;call master_net
mov nosetjmp,2
vbl
directjeu:
call master1
trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty:

;*************************** SLAVE ********************************
;;cmp [master],1
;;jne trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2
;;call slave1
;;trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2:
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

;--------------- lecture des ordre ------------------------------
cmp byte ptr [ordre2],'M'  ;pour slave...
je hoooooooop              ;saute au menu si ordre...
;--------------------------------------------------
cmp byte ptr [ordre2],'%' ;indique nouvelle manche
je nouvelle_manche3
;-*-------------------------------

;-- sortie forcee..
cmp [master],0
je ertyerttyrrtyyrtretertdgrfgd
cmp sortie_slave,0 ;cmp sortie,0 ;
jne rtertertyeertrteertterertertterertterert
jmp retertdgrfgd
ertyerttyrrtyyrtretertdgrfgd:


cmp [master],0
jne retertdgrfgd

cmp byte ptr [sortie],1 ;eSC.
jne retertdgrfgd
;on est master.. et echap est appuyé...
;****************** SORTIE... uniquement pour le master *********************

mov byte ptr [ordre2],'M'  ;donne ordre de sortie
jmp retertdgrfgd

; récupere les touches pour chaque joueur et pour
                           ; tous les différents ordinateurs.
;call master1               ; comme ca... les autres vont recup ordre2..
;jmp hoooooooop


;****************************************************************************
rtertertyeertrteertterertertterertterert:
        mov ax,3h
        int 10h
;----
;cmp previentlmesenfants,1 ;pour slave: affiche messgae fin
;jne ertertterrtertyutyutyutyutyutyuutytyu
;lea edx,gameover
;mov ah,09h
;int 21h
;ertertterrtertyutyutyutyutyutyuutytyu:
;---


rtertertyeertrteertterertertterertterert2:
busy_ou: ;fin koi

;--effacage de fin ... ---
;cmp [mechant],1
;je mechant3
mechant5:

;PUSHALL
;mov ax,02fh
;mov ax,1684h
;mov bx,07fe0h
;int 2Fh
;mov ax,es
;call affsigne
;
;POPALL


;               mov eax,[adresse_des_fonds] ; dd 0h ;,100000h,200000h,100000h
;        mov eax,[differents_offset_possible+8*4*4]
;        call num
;        sagouin texte_fin

      ;  call gus_init


;cmp [jesus_mode],0
;jne reteretrertert5445870t
;packets_jeu_envoyes dw 0
;packets_jeu_recus   dw 0
;call affichage_stats
;call affichage_rec
;control_joueur dd 8 dup (?) ;-1,6,32,32+6,-1,-1,-1,-1
;mov eax,control_joueur
;call num

;mov ecx,9
;mov esi,offset victoires
;money_train:
;lodsd
;call affsigne
;loop money_train

;lea edx,last_name
;mov ah,9
;int 21h

;mov ah,02ah
;int 21h
;cmp cx,1998
;jb tranquilleee
;ja rtertertyeertrteertterertertterertterertertrtetyrtyuyuuie
;cmp dh,3
;ja rtertertyeertrteertterertertterertterertertrtetyrtyuyuuie
;tranquilleee:
;
;        lea edx,information2
;        mov ah,9
;        int 21h
;        mov bh,00000000B ;indique clignotement
;        mov bl,11 ;5 ;rouge
;        call last_color
;rtertertyeertrteertterertertterertterertertrtetyrtyuyuuie:
;mov cl,[last_sucker]
;nonoiutryyrtryt:
;cmp [last_sucker],cl
;je nonoiutryyrtryt


;;------------ dky -
;push ds
;pop  es
;
;xor al,al
;lea edi,pal_affichée
;mov cx,768
;rep stosb
;call affpal
;
;mov esi,offset darky
;mov edi,0b8000h
;mov ecx,1000
;rep movsd
;mov dl,79
;mov dh,23
;mov al,0
;mov bh,0
;mov ah,2
;int 10h
;
;;lea esi,pal_txt_debut
;
;;rep movsb
;
;;------------
;
;mov cx,63
;rereerter:
;call affpal
;call vbl
;
;;lea esi,pal_txt_debut
;mov bx,768
;xor al,al
;lea esi,pal_txt_debut
;lea edi,pal_affichée
;oohiu:
;;lodsb
;cmp al,[edi]
;cmpsb
;je ertterrtyrtrtyrty
;inc byte ptr [edi-1]
;ertterrtyrtrtyrty:
;;inc edi
;
;dec bx
;jnz oohiu
;;rep stosb
;
;
;dec cx
;jnz rereerter


;cmp windows,1
;je oregreteiiooi
;
;        lea edx,information3
;        mov ah,9
;        int 21h
;        mov bh,00000000B ;indique clignotement
;        mov bl,15
;        call last_color
;oregreteiiooi:

;master      db 0 ; 0 = OUI

;cmp byte ptr [lost_conney],1 ;eSC.
;je r4564654eertrterereetr

;cmp [master],0
;jne r4564654eertrterereetr
;cmp on_a_bien_fait_une_partie,0
;jne r4564654eertrterereetr

;        lea edx,information5
;        mov ah,9
;        int 21h


;lea ebx,beginningdata
;lea eax,enddata
;sub eax,ebx
;call printeax


;r4564654eertrterereetr:


;lea edx,nick_t
;mov ah,9
;int 21h
        mov al,[lost_conney]
        mov ah,4ch                      ; AH=4Ch - Exit To DOS
        int 21h                         ; DOS INT 21h
;mov ax,bidouille
;push ax
;pop cs
;xchg ax,cs
;;push cs
;pop cs
;int 20h

quitte_baby: ;cas de connection lost... pour slave...
POPALL
        mov ax,3h
        int 10h
mov [lost_conney],1

mov dl,''
mov ah,2
int 21h

;mov trygain,1
;jmp tryagain
;
;mov esi,0b8000h
;mov [esi],651516

jmp rtertertyeertrteertterertertterertterert2

;mechant3:
;
;        mov ax,3h
;        int 10h
;
;;load_pcx proc near ; ecx: offset dans le fichier.
;;                   ; edx: offset nom du fichier
;;                   ; edi: viseur dans données ou ca serra copié (ax:)
;;                   ; ebx: nombre de pixels dans le pcx
;;
;;pushad
;;push es ds
;;
;;mov [load_pcx_interne],ebx
;;
;;
;; mov es,ax
; mov edx,offset iff_file_name
;; mov ah,09h
;; int 21h
; xor eax,eax
; mov al,01h ;ecriture;
; mov ah,03dh
; int 21h
;
;;xor ebx,ebx
;mov ebx,eax
;mov ah,040h
;mov ecx,250000 ;juste le code
;push ds
;
;push fs
;pop  ds
;xor edx,edx
;int 21h
;;  AH     = 40h
;;  BX     = file handle
;;  ECX    = number of bytes to write
;;  DS:EDX -> buffer to write from
;
;pop ds
;jmp mechant5

master1 proc near


;je no_fucking_vbl
;TOFIX

;jmp ouiouirt
;no_fucking_vbl:
;inc dword ptr [changement]
;ouiouirt:

;--- intelligence draw game ------------------------------------------------
cmp byte ptr [ordre2],'D'
jne trtyrtyrtyrtyrtyterterertrteert

;*** affichage draw game
cmp [duree_draw],duree_draw2
jne erertertteryr
mov [affiche_pal],1
erertertteryr:
call copie_le_fond_draw
call aff_page2
jmp rtyrtyrtytyrrtyyttyutyutyutyutyutyutyutyutyuyuttyu
retetrterterertertrteertertertertre:
;;;- pas asssez memoire -
;mov ah,02h
;mov dh,24
;mov dl,0
;mov bh,0
;int 10h
;call affiche_en_mode_texte
rtyrtyrtytyrrtyyttyutyutyutyutyutyutyutyutyuyuttyu:
;**************************************************************************
dec [duree_draw]
jnz reterertertert
mov [ordre2],'%' ;indique nouvelle manche
reterertertert:

;,return_presseque_master  ordre2 '%'

;--- pour pas ke le master kitte de suite kan on sort d'un draw game forcé

cmp [duree_draw],450 ;pas tout de suite kan meme...
ja ertetrtrkjjklmkjlmetkjlmdikgrhrfhgrrethghkgh
cmp word ptr bdraw666,'99'
je ertetrtrkjjklmkjlmetkjlmdikgrhrfhgrrethghkgh
touche_presseque_master  ordre2,'%'
ertetrtrkjjklmkjlmetkjlmdikgrhrfhgrrethghkgh:

cmp [duree_draw],400 ;pas tout de suite kan meme...
ja rerteertertertert3r0
touche_presse ordre2 '%' ;saute au menu...
rerteertertertert3r0:

call compact
get_all_infos2         ; récupere les touches pour chaque joueur et pour
;                       ; tous les différents ordinateurs.
jmp exitFunction
trtyrtyrtyrtyrtyterterertrteert:
;---------------------------------------------------------------------------

;--------------- intelligence jeu ------------------------------
cmp byte ptr [ordre2],'' ;uniqUEMENT si on est dans le jeu.
jne terterertrteert
call gestion_jeu
;----affichage jeu -------------------

cmp byte ptr [ordre2],'Z' ;uniqUEMENT si on a quitté le jeu en fait...
je  meeeeeed

call compact
get_all_infos2         ; récupere les touches pour chaque joueur et pour
                       ; tous les différents ordinateurs.
                       ; si ca n'a pas changé...
                       ; l'ordre peut avoir changé mais seulement a la fin...

call rec_play_touches  ;enregistre/joue les touches (pour le REPLAY...)

cmp byte ptr [ordre2],'' ;uniqUEMENT si on a pas quitté le jeu en fait...
jne yttyutyutyutyutyutyutyutyutyuyuttyu

;*************** affichage *************************************************
;master db 0 ; 0 = OUI
;            ; 1 = NON
;----- affichage de l'écran local. l'ancien ecran...
cmp [last_sucker],0
jne yttyutyutyutyutyutyutyutyutyuyuttyu
call copie_le_fond
call affiche_sprites
call aff_page2
;jmp yttyutyutyutyutyutyutyutyutyuyuttyu
;retetrterterertertrteertertertert:
;call affiche_en_mode_texte
yttyutyutyutyutyutyutyutyutyuyuttyu:
jmp exitFunction
terterertrteert:
;--------------------------------------------------


;---- victoire supreme -------------------------------------------------------
cmp byte ptr [ordre2],'V'
jne etrertertrtertertyerterttrtyrtyrtyrtyrtyterterertrteert
victoire_sup:
cmp [duree_vic],duree_vic2 ;pour kitter...
jne kierertertteryr
mov [affiche_pal],1
kierertertteryr:
call copie_le_fond_vic
call aff_page2
;jmp kirtyrtyrtytyrrtyyttyutyutyutyutyutyutyutyutyuyuttyu
kiretetrterterertertrteertertertertre:
;--- intelligence  vic ---
dec [duree_vic]
jnz ireterertertertu
mov [ordre2],'M' ;indique saute au menu...
ireterertertertu:

cmp [duree_vic],duree_vic2-60 ;pas tout de suite kan meme...
ja rerteertertertert



cmp [duree_vic],duree_vic2-60 ;pas tout de suite kan meme.
ja rerteertertertertPOPOP
touche_presseque_master  ordre2,'M'
rerteertertertertPOPOP:

cmp [duree_vic],duree_vic2/2 ;pas tout de suite kan meme...
ja rerteertertertert
touche_presse ordre2 'M' ;saute au menu...
rerteertertertert:
;------------------------------
call compact
get_all_infos2         ; récupere les touches pour chaque joueur et pour
                       ; tous les différents ordinateurs.
                       ; si ca n'a pas changé...
                       ; l'ordre peut avoir changé mais seulement a la fin...

jmp exitFunction
etrertertrtertertyerterttrtyrtyrtyrtyrtyterterertrteert:
;-----------------------------------------------------------------------------


;------ intelligence medaille ---
cmp byte ptr [ordre2],'Z'
jne rtyerterttrtyrtyrtyrtyrtyterterertrteertrtrtrtrtyyrtyooooooooooooo
meeeeeed:
;*****************************************************************************


cmp [duree_med],duree_med2 ;pour kitter...
jne ierertertteryr
mov [affiche_pal],1
ierertertteryr:

call copie_le_fond_med
call aff_page2
jmp irtyrtyrtytyrrtyyttyutyutyutyutyutyutyutyutyuyuttyu
iretetrterterertertrteertertertertre:
;-------------- pas asssez memoire -----------
;mov ah,02h
;mov dh,24
;mov dl,0
;mov bh,0
;int 10h
irtyrtyrtytyrrtyyttyutyutyutyutyutyutyutyutyuyuttyu:
pas_med:
;----------------------------------------------------------------
;--- intelligence mediakle ---
;;                   ;+ 1 db= faut afficher la brike ki clignote ou pas???
;----------- intelligence clignotement... ----
SOUND_FAC BLOW_WHAT2
mov eax,[changement]
and eax,0000111111B
cmp eax,32
jne tout_
mov byte ptr [briques+8*4],1
tout_:
or  eax,eax
jnz tout_3
bruit3 3,35,BLOW_WHAT2 ;sonne
mov byte ptr [briques+8*4],0
tout_3:
;----------------------------------

dec [duree_med]
jnz ireterertertert
mov [ordre2],'%' ;indique nouvelle manche

ireterertertert:

cmp [duree_med],duree_med2-1*90 ;pas tout de suite kan meme.
ja rerteertertertertPOPOP2
touche_presseque_master  ordre2,'%'
rerteertertertertPOPOP2:

;------------------- pas de quittage trop hatif...
cmp [duree_med],duree_med2-3*60 ;3 secondes minimum
ja okokokokokokok345345345
touche_presse ordre2 '%'
okokokokokokok345345345:
;-----------------------------------

;sauf si on aurait gagné...
cmp [ordre2],'%'
jne iertrtrterteert
xor ebx,ebx
ierterertertrtyetyutyutyuutytyutyu:
cmp [victoires+ebx],5
jne iertterteteertzerzerzerzerrteretr
mov byte ptr [ordre2],'V' ;victoire supreme
jmp victoire_sup
iertterteteertzerzerzerzerrteretr:
add ebx,4
cmp ebx,4*8
jne ierterertertrtyetyutyutyuutytyutyu
iertrtrterteert:
;---

rtyerterttrtyrtyrtyrtyrtyterterertrteertrtrtrtrtyyrtyooooooooooooo:
;------------------------------


call compact
get_all_infos2         ; récupere les touches pour chaque joueur et pour
                       ; tous les différents ordinateurs.
exitFunction:
mov byte ptr [donnee2+8*7],0
mov byte ptr [donnee2+8*7+1],0
mov byte ptr [donnee2+8*7+2],0
ret
;=================================================
endp

doStuffClavierExtended proc near

;28   ENTER        (KEYPAD)     !        75   LEFT         (NOT KEYPAD) !
;29   RIGHT CONTROL             !        77   RIGHT        (NOT KEYPAD) !
;42   PRINT SCREEN (SEE TEXT)            79   END          (NOT KEYPAD) !
;53   /            (KEYPAD)     !        80   DOWN         (NOT KEYPAD) !
;55   PRINT SCREEN (SEE TEXT)   !        81   PAGE DOWN    (NOT KEYPAD) !
;56   RIGHT ALT                 !        82   INSERT       (NOT KEYPAD) !
;71   HOME         (NOT KEYPAD) !        83   DELETE       (NOT KEYPAD) !
;72   UP           (NOT KEYPAD) !       111   ccc
;73   PAGE UP      (NOT KEYPAD) !
;
;               db 'UP             ',3 ;112
;               db 'DOWN           ',3 ;113
;               db 'LEFT           ',3 ;114
;               db 'RIGHT          ',3 ;115

mov byte ptr [clavier_extanded+72],72 ; db 128 dup (123)
mov byte ptr [clavier_extanded+80],80
mov byte ptr [clavier_extanded+91],91
mov byte ptr [clavier_extanded+92],92
mov byte ptr [clavier_extanded+93],93
mov byte ptr [clavier_extanded+29],123
mov byte ptr [clavier_extanded+53],116
mov byte ptr [clavier_extanded+79],117
mov byte ptr [clavier_extanded+83],118
mov byte ptr [clavier_extanded+82],122
mov byte ptr [clavier_extanded+73],120
mov byte ptr [clavier_extanded+71],121
mov byte ptr [clavier_extanded+81],119
mov byte ptr [clavier_extanded+56],124
mov byte ptr [clavier_extanded+28],125
mov byte ptr [clavier_extanded+55],84 ;print screen (2/2)

;----------------------------------------------------------------------------.
mov byte ptr [clavier_extanded+72],112
mov byte ptr [clavier_extanded+80],113
mov byte ptr [clavier_extanded+75],114
mov byte ptr [clavier_extanded+77],115
;----------------------------------------------------------------------------.


ret
endp

;cmp [jesus_mode],0
;jne reteretrertert5445870t
;packets_jeu_envoyes dw 0
;packets_jeu_recus   dw 0
a_la_ligne proc near
PUSHALL
mov dl,10
mov ah,2
int 21h
mov dl,13
mov ah,2
int 21h
POPALL
ret
endp

init_menu proc near
PUSHALL

;--- pour le deuxieme tours.. car special... serra a 2
; econo est ensuite mis a 0
; et serra remis a 1 ke si on finit le record (pas de esc)
;cmp economode,1
;jne tyjktrjhtjhrtjtjtrhlhhjhyhjyjhlyjhly
;mov temps_avant_demo,1 ;ttp ;temps_avant_demo2
;;mov [sors_du_menu_aussitot],1
;mov special_on_a_loadee_nivo,2
;mov economode,2
;tyjktrjhtjhrtjtjtrhlhhjhyhjyjhlyjhly:

cmp special_on_a_loadee_nivo,1
jne ertterterrtertytyrrtyrtyrtyrtyrtyrtyrty

mov temps_avant_demo,1 ;ttp ;temps_avant_demo2
mov special_on_a_loadee_nivo,2
;mov [sors_du_menu_aussitot],1
ertterterrtertytyrrtyrtyrtyrtyrtyrtyrty:

mov [affiche_pal],1 ;!!!
mov [sortie],0
mov [attente_nouveau_esc],20
mov byte ptr [ordre],'S'
mov byte ptr [ordre2],''
push ds
pop es

cmp [master],0
je trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2erte34fgh
POPALL
ret
;*************** QUE MASTER -******************
trtyrtrtyrtyrtyrtyrtytyrrtyrtytyryrtrty2erte34fgh:

push ax
mov al,team3_sauve
and al,3
mov team3,al
pop ax
;--- jsute utilie pour le debut..
;pour remplir le nombre de joueurs dans le menu...
;kil faut pour commencer une partie.
cmp [team3],0
jne tetrtyertyrdfgdfggdffgdgdf0
PUSHALL
lea esi,n_team
lea edi,team
mov ecx,9
rep movsd
POPALL
tetrtyertyrdfgdfggdffgdgdf0:
cmp [team3],2
jne tetrtyertyrdfgdfggdffgdgdf
PUSHALL
lea esi,s_team
lea edi,team
mov ecx,9
rep movsd
POPALL
tetrtyertyrdfgdfggdffgdgdf:
cmp [team3],1
jne tetrtyertyrdfgdfggdffgdgdfE
PUSHALL
lea esi,c_team
lea edi,team
mov ecx,9
rep movsd
POPALL
tetrtyertyrdfgdfggdffgdgdfE:

;mov [last_sucker],0 ;derniere touche... pour attente zaac pic
lea edi,total_play
xor eax,eax
mov ecx,64/4
rep stosd
lea edi,fx
xor ax,ax
mov ecx,14
rep stosw

mov edi,offset total_t
xor eax,eax
mov ecx,(64/4)*8
rep stosd
lea edi,name_joueur
xor eax,eax
mov ecx,8
rep stosd
mov esi,offset message1
mov edi,offset texte1
mov ecx,32
rep movsd
mov esi,offset message1
mov ecx,32
rep movsd
mov esi,offset message1
mov ecx,32
rep movsd
mov esi,offset message1
mov ecx,32
rep movsd
mov esi,offset message1
mov ecx,32
rep movsd
mov esi,offset message1
mov ecx,32
rep movsd
mov esi,offset message1
mov ecx,32
rep movsd
mov esi,offset message1
mov ecx,32
rep movsd
lea edi,control_joueur ;fait correspondre é cpu pour affichage des noms
mov eax,64*8
mov ecx,8
rep stosd
mov [nombre_de_dyna],0
mov nb_ai_bombermen,0
lea edi,temps_joueur
mov eax,temps_re_menu
mov ecx,8
rep stosd


mov action_replay,0                     ;pas si on est en play

lea edi,lapipipino ;pour pu kil soit considere comme un lapin
xor eax,eax
mov ecx,8
rep stosd

POPALL
ret
init_menu endp

_TEXT   ends ;IGNORE

_DATA   segment use32 dword public 'DATA' ;IGNORE
;ééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééé
; DATA
;ééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééé

beginningdata db 1

donoterasekeys db 0

liste_de_machin dd 1000000000,100000000,10000000,1000000,100000,10000,1000,100,10,1,0

;// LOCAL VARIABLES R/W BUT -> NOT SHARED

infojoueur2 dd 5000,5000,5000,1,0

tecte2   dd 0
scrollyF dd 0
scrolly   db 6*328 dup (0)

special_clignotement dd ?

trucs db '0123456789ABCDEF'
last_voice dd 0
BLOW_WHAT2  dw 14 dup (?)
BLOW_WHAT     dw   14 dup (0)


;---- allignement = ok :)
slowcpu    dd 0
paaaaaaading db 35 dup (0)
buffer      db 0FFFFh dup (0)
paaaaading db 11 dup (0)

message2 db '    is'
db 'ready '
db '2 kill'
db '              '
db '    is'
db 'ready '
db '2 kill'
db '              '
db 'hosted'
db 'by cpu'
db ' nb:  '
db '              '
db 'hosted'
db 'by cpu'
db ' nb:  '
db '              '

total_liste dd ?

bigendianin dd 0
bigendianout dd 0

dataloaded db 1

clavier db 128 dup (0)

;// FIRST READ ONLY VARIBLES....  -> NOT SHARED

taille_exe_gonfle dd 0255442

playSoundFx db 0

master      db 0 ; 0 = OUI
                 ; 1 = NON
;----

clavier_stuff db 0 ;0 rien
clavier_stuff2 db 0 ;0 rien
clavier_extanded db 128 dup (0)
include pal_pic.inc
include pal_pic2.inc
include pal_jeu.inc
include pal_med.inc
include pal_vic.inc
include pal_draw.inc
include blinking.inc

isbigendian db 1


;touches par default.. ;-1 = actif...
touches_  dd 114,115,112,113,82,83,125,-1,20,21,16,30,57,15,58     ,-1,,0,0,0,0,0,0,0,            00,,0,0,0,0,0,0,0,            00,,0,0,0,0,0,0,0,            00,,0,0,0,0,0,0,0,            00,,0,0,0,0,0,0,0,            00,,0,0,0,0,0,0,0,            00


tected  db 'welcome to mr.boom v4.2 *'
tecte    db '  players can join the game using their action keys...  '
db '  use the b button to drop a bomb   a to trigger the bomb remote control   x to jump (if you are riding a kangaroo)   select to add a bomber-bot   start to start!   graphics by zaac exocet easy and marblemad   musics by 4-mat carter estrayk heatbeat jester kenet parsec quazar rez and ultrasyd   (c) 1997-2020 remdy software.     (wrap time)  ',0dbh
db 512 dup(0)
message1 db ' join '
db '  us  '
db '  !!  '
db '              '
db '      '
db '      '
db '      '
db '              '
db ' push '
db ' fire '
db '  !!  '
db '              '
db '      '
db '      '
db '      '
db '              '


message3 db 'name ?'
db '      '
db '      '
db '              '
db 'name ?'
db '      '
db '      '
db '              '
db 'name ?'
db '      '
db '      '
db '              '
db '      '
db '      '
db '      '
db '              '

mess_kli db 'kli kl'
db ' kli k'
db 'i kli '
db '              '
db ' kli k'
db 'i kli '
db 'li kli'
db '              '
db 'i kli '
db 'li kli'
db 'kli kl'
db '              '
db 'li kli'
db 'kli kl'
db ' kli k'
db '              '

mess_luc db 'luc lu'
db ' luc l'
db 'c luc '
db '              '
db ' luc l'
db 'c luc '
db 'uc luc'
db '              '
db 'c luc '
db 'uc luc'
db 'luc lu'
db '              '
db 'uc luc'
db 'luc lu'
db ' luc l'
db '              '

mess_frd db '      '
db ' fred '
db '      '
db '              '
db '      '
db 'point!'
db '      '
db '              '
db '      '
db ' fred '
db '      '
db '              '
db '      '
db 'point!'
db '      '
db '              '


mess_jag db 'jaguar'
db '      '
db '      '
db '              '
db '      '
db 'jaguar'
db '      '
db '              '
db '      '
db '      '
db 'jaguar'
db '              '
db '      '
db 'jaguar'
db '      '
db '              '

mess_din db '      '
db 'dines '
db '      '
db '              '
db '      '
db 'dines!'
db '      '
db '              '
db '      '
db 'dines '
db '      '
db '              '
db '      '
db 'dines!'
db '      '
db '              '

mess_jdg db 'judge '
db '      '
db 'j.f.f.'
db '              '
db 'miguel'
db '      '
db 'j.f.f.'
db '              '

mess_rmd db '      '
db 'remdy.'
db '      '
db '              '
db '      '
db 'remdy '
db '      '
db '              '
db '      '
db 'remdy.'
db '      '
db '              '
db '      '
db 'remdy '
db '      '
db '              '

mess_ors db '      '
db ' orsi '
db '      '
db '              '
db '      '
db ' orsi '
db '      '
db '              '
db '      '
db ' orsi '
db '      '
db '              '
db '      '
db ' orsi '
db '      '
db '              '

mess_kor db 'enjoy.'
db 'meteor'
db '      '
db '              '
db 'think.'
db 'meteor'
db '      '
db '              '
db 'drink.'
db 'meteor'
db '      '
db '              '
db '      '
db ' kor! '
db '      '
db '              '

mess_sl1 db '      '
db ' s    '
db '      '
db '              '
db '      '
db ' sl   '
db '      '
db '              '
db '      '
db ' sli  '
db '      '
db '              '
db '      '
db ' slin '
db '      '
db '              '


mess_adr db 'lechat'
db '      '
db '      '
db '              '
db 'lechat'
db 'login '
db '      '
db '              '
db 'lechat'
db 'login '
db ' root '
db '              '
db 'dpx 20'
db 'xwbh44'
db 'orsay!'
db '              '


mess_wil db 'willy!'
db 'united'
db 'lamers'
db '              '
db 'willy!'
db 'united'
db 'lamers'
db '              '


mess_exo db 'exocet'
db '      '
db 'j.f.f.'
db '              '
db 'exocet'
db '      '
db 'j.f.f.'
db '              '

mess_cl  db 'cl!nph'
db ' cle. '
db ' aner '
db '              '
db 'cl!nph'
db ' cle. '
db ' aner '
db '              '

mess_ben db 'benji!'
db '      '
db 'j.f.f.'
db '              '
db 'benji!'
db '      '
db 'j.f.f.'
db '              '

mess_aaa db 'anony.'
db 'mous ?'
db 'pffff.'
db '              '
db 'lamer!'
db 'lamer!'
db 'lamer!'
db '              '

mess_fzf db '      '
db ' fzf! '
db '      '
db '              '
db '  le  '
db 'maitre'
db 'est...'
db '              '
db '  de  '
db 'retour'
db '  !!  '
db '              '
db '      '
db ' fzf! '
db '      '
db '              '



mess_het db 'hetero'
db '  of  '
db 'razor!'
db '              '
db 'if you'
db 'are to'
db ' slow '
db '              '
db 'i will'
db 'insert'
db 'a bomb'
db '              '
db '  in  '
db ' your '
db ' ass! '
db '              '

mess_big db '      '
db ' b... '
db '      '
db '              '
db '      '
db ' bi.. '
db '      '
db '              '
db '      '
db ' big. '
db '      '
db '              '
db '      '
db 'jokes!'
db '      '
db '              '

mess_hak db 'hak ha'
db ' hak h'
db 'k hak '
db '              '
db ' hak h'
db 'k hak '
db 'ak hak'
db '              '
db 'k hak '
db 'ak hak'
db 'hak ka'
db '              '
db 'ak hak'
db 'hak ha'
db ' hak h'
db '              '



mess_jc  db '      '
db '  jc  '
db '      '
db '              '
db '      '
db '  jc  '
db '      '
db '              '

defo db 'aaa',87h

;(a)pocalypse de rechange:
truc_fin_s   db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,001,002,003,004,005,006,007,008,009,010,011,012,013,014,015,016,017,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,052,053,054,055,056,057,058,059,060,061,062,063,064,065,066,067,018,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,051,096,097,098,099,100,101,102,103,104,105,106,107,108,109,068,019,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,050,095,132,255,255,255,255,255,255,255,255,255,255,255,110,069,020,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,049,094,131,255,255,255,255,255,255,255,255,255,255,255,111,070,021,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,048,093,130,255,255,255,255,255,255,255,255,255,255,255,112,071,022,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,047,092,129,255,255,255,255,255,255,255,255,255,255,255,113,072,023,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,046,091,128,255,255,255,255,255,255,255,255,255,255,255,114,073,024,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,045,090,127,126,125,124,123,122,121,120,119,118,117,116,115,074,025,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,044,089,088,087,086,085,084,083,082,081,080,079,078,077,076,075,026,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,043,042,041,040,039,038,037,036,035,034,033,032,031,030,029,028,027,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 000 ;vitesse

truc_fin_soccer   db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,001,002,003,004,005,006,007,008,009,010,011,012,013,014,015,016,017,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,034,033,032,031,030,029,028,027,026,025,024,023,022,021,020,019,018,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,035,036,037,038,039,040,041,042,043,044,045,046,047,048,049,050,051,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,050,050,053,053,054,055,056,255,255,255,058,057,056,055,054,053,052,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,075,074,073,072,071,070,255,255,255,255,255,059,060,061,062,063,064,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,064,065,066,067,068,069,255,255,255,255,255,070,069,068,067,066,065,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,063,062,061,060,059,058,255,255,255,255,255,071,072,073,074,075,076,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,052,053,054,055,055,056,057,255,255,255,083,082,081,080,079,078,077,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,051,050,049,048,047,046,045,044,043,042,041,040,039,038,037,036,035,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,018,019,020,021,022,023,024,025,026,027,028,029,030,031,032,033,034,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,017,016,015,014,013,012,011,010,009,008,007,006,005,004,003,002,001,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 002;vitesse

truc_fin_s_c db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,134,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 000 ;vitesse


;pour le nivo micro...(hell)
truc_fin_s_m db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,001,001,001,001,001,001,001,001,001,001,001,001,001,001,001,001,001,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,015,015,015,015,015,015,015,015,015,015,015,015,015,015,015,015,015,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,030,030,030,030,030,030,030,030,030,030,030,030,030,030,030,030,030,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,045,045,045,045,045,045,045,045,045,045,045,045,045,045,045,045,045,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,060,060,060,060,060,060,060,060,060,060,060,060,060,060,060,060,060,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,075,075,075,075,075,075,075,075,075,075,075,075,075,075,075,075,075,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,090,090,090,090,090,090,090,090,090,090,090,090,090,090,090,090,090,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,105,105,105,102,105,105,105,105,105,105,105,105,105,105,105,105,105,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,120,120,120,120,120,120,120,120,120,120,120,120,120,120,120,120,120,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0111B ;vitesse

;truc_fin_foot db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,001,022,023,044,045,066,067,088,225,078,077,056,055,034,033,012,011,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,002,021,024,043,046,065,068,087,225,079,076,057,054,035,032,013,010,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,003,020,025,042,047,064,069,086,225,080,075,058,053,036,031,014,009,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,004,019,026,041,048,063,070,085,226,081,074,059,052,037,030,015,008,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,005,018,027,040,049,062,071,084,226,082,073,060,051,038,029,016,007,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,006,017,028,039,050,061,072,083,226,083,072,061,050,039,028,017,006,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,007,016,029,038,051,060,073,082,227,084,071,062,049,040,027,018,005,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,008,015,030,037,052,059,074,081,227,085,070,063,048,041,026,019,004,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,009,014,031,036,053,058,075,080,227,086,069,064,047,042,025,020,003,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,010,013,032,035,054,057,076,079,228,087,068,065,046,043,024,021,002,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,011,012,033,034,055,056,077,078,228,088,067,066,045,044,023,022,001,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
;             dd 0111B ;vitesse

truc_fin_s_n db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,100,100,100,100,100,255,040,041,042,043,044,255,085,085,085,085,085,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,100,100,100,100,100,255,047,255,046,255,045,255,085,085,085,085,085,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,100,100,100,100,100,255,255,255,255,255,255,255,085,085,085,085,085,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,100,100,100,100,100,255,255,255,255,255,255,255,085,085,085,085,085,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,100,100,100,100,100,001,255,255,255,255,255,020,085,085,085,085,085,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,070,070,070,070,070,030,255,255,255,255,255,010,110,110,110,110,110,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,070,070,070,070,070,255,255,255,255,255,255,255,110,110,110,110,110,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,070,070,070,070,070,255,255,255,255,255,255,255,110,110,110,110,110,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,070,070,070,070,070,255,056,255,057,255,058,255,110,110,110,110,110,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,070,070,070,070,070,255,055,054,053,052,051,255,110,110,110,110,110,000,0,0,0,0,0,0,0,0,0,0,0,0,0
db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,0,0,0,0,0,0,0,0,0,0,0,0,0
dd 0011B ;vitesse


truc_s  db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,0,0,2,2,2,0,0,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,2,1,0,1,2,1,0,1,2,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,2,1,0,1,2,1,0,1,2,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,0,0,2,2,2,0,0,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

truc_foot  db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,0,1,2,1,2,1,2,1,0,1,2,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,0,0,0,2,2,2,2,2,0,0,0,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,0,1,2,1,0,1,2,1,0,1,2,1,0,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,0,0,0,2,2,2,2,2,0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,0,1,2,1,0,1,2,1,0,1,2,1,0,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,0,0,0,2,2,2,2,2,0,0,0,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,0,1,2,1,0,1,2,1,0,1,2,1,0,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,0,0,0,2,2,2,2,2,0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,2,1,0,1,2,1,2,1,2,1,0,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

truc_soccer       db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

db 1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,0,1,2,1,2,1,2,1,2,1,2,1,0,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,0,0,0,2,2,2,2,2,2,2,2,2,0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,1,2,1,2,1,0,1,2,1,2,1,0,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

db 1,2,2,2,2,0,0,0,2,2,2,0,0,0,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,0,0,0,2,2,2,0,0,0,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,1,2,1,2,1,0,1,2,1,2,1,0,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

db 1,2,0,0,0,2,2,2,2,2,2,2,2,2,0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,0,1,2,1,2,1,2,1,2,1,2,1,0,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1

db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1


;truc_n  db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;       db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0

truc_n  db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,0,0,1,2,0,0,0,2,1,0,0,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,0,1,2,1,2,1,2,1,0,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,1,2,2,2,2,2,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,1,1,1,1,1,1,2,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,1,2,2,2,2,2,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,0,1,2,1,2,1,2,1,0,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,0,0,1,2,0,0,0,2,1,0,0,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

truc_c  db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

truc_h  db 1,66,66,66,66,66,66,66,1,1,1,66,66,66,66,66,66,66,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,66,1,1,1,1,1,1,1,1,1,1,1,1,1
db 66,66,66,66,66,66,66,66,66,66,66,66,66,66,66,66,66,66,66,1,1,1,1,1,1,1,1,1,1,1,1,1

truc_f  db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,2,1,1,1,2,1,2,1,1,1,2,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,2,2,2,0,0,0,1,2,2,0,0,0,2,2,2,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,1,1,0,1,2,1,1,1,0,1,1,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,2,2,2,2,2,2,1,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,1,2,0,0,2,2,2,2,2,2,1,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,1,1,0,1,2,1,1,1,2,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,2,2,2,2,1,0,2,2,2,0,0,0,2,2,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,1,1,2,1,2,1,1,1,0,1,1,1,2,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1


truc_neige  db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,2,1,0,1,2,1,2,1,2,1,2,1,2,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,0,0,2,2,2,2,2,2,0,0,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,2,1,1,1,2,1,2,1,0,1,0,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,1,1,1,2,2,2,2,2,0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,2,1,1,1,2,1,2,1,2,1,0,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,1,2,1,2,1,0,1,2,1,0,1,2,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,1,2,1,2,1,2,1,2,1,2,1,2,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

;--- laisser ensemble
truc2_save_foot db 0,0,0,0,0,0,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,00,0,000,00,00,0,0,0,0,0,0,94,0,0,0,0,0,0,0,0,0,0,0,0,0,0
truc2_save   db 32*0,0,0,0,0,0,0,0,0,0,0,0,0
;---
truc2_save_n db 0,0,0,0,0,0,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,00,0,114,74,84,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,00,00,0,00,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,00,0,104,74,94,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0



;0= face        bas.
;8= droite      droite
;16= gauche     gauche
;24= haut       haut
;0;8;24;



ia dd 16,0,8,24,0,8,24,16,0,24,16,0,8,16,0,24

offset_supporter db 0,24,0,24*2
offset_cameraman db 0*lft,1*lft,2*lft,1*lft ;4
db 12 dup (0);

db 0*lft,3*lft,4*lft,3*lft
db 12 dup (0);

;                 db 0*lft,4*lft,4*lft,4*lft,3*lft,4*lft,4*lft,4*lft
;                 db 8 dup (0);
;
;                 db 16 dup (0);

;--

db 0*lft,4*lft,4*lft,4*lft,4*lft,4*lft,4*lft,4*lft
db 8 dup (4*lft);

db 8 dup (0);

db 0*lft,5*lft,6*lft,5*lft
db 12 dup (0);

db 8 dup (0);

db 0*lft,1*lft,2*lft,1*lft ;4
db 12 dup (0);


;diffents modes demo :)) mrb.. record.. tout ca koi
differentesply dd 1966080+64000*25 ;lune1.mrb
dd 1966080+64000*6  ;nuage1.mrb record5.mrb
dd 1966080+64000*13 ;foot1.mrb
dd 1966080+64000*2  ;micro1.mrb record1.mrb
dd 1966080+64000*3  ;jungle1.mrb record2.mrb
dd 1966080+64000*4  ;rose1.mrb     record3.mrb
dd 1966080+64000    ;neige1.mrb record0.mrb
dd 1966080+64000*5  ;fete1.mrb  record4.mrb

dd 1966080+64000*26 ;lune2.mrb
dd 1966080+64000*20 ;nuage2.mrb
dd 1966080+64000*14 ;foot2.mrb
dd 1966080+64000*19 ;micro2.mrb
dd 1966080+64000*18 ;jungle2.mrb
dd 1966080+64000*17 ;rose2.mrb
dd 1966080+64000*16 ;neige2.mrb
dd 1966080+64000*15 ;fete2.mrb

offset_pause dd 0,48,0,48,0,48,48*2,48*3,48*2,48
dd 0,48,0,48
dd 0,48,0,48,0,48,48*2,48*3,48*2,48
dd 0,48,0,48,0,48,0,48,0,48,0,48,0,48,0,48,0
dd 666

offset_si dd offset mess_rmd
dd 32
dd offset mess_ors
dd 32
dd offset mess_kli
dd 32
dd offset mess_aaa
dd 16
dd offset mess_jc
dd 16
dd offset mess_exo
dd 16
dd offset mess_ben
dd 16
dd offset mess_wil
dd 16
dd offset mess_cl
dd 16
dd offset mess_jdg
dd 16
dd offset mess_big
dd 32
dd offset mess_kor
dd 32
dd offset mess_fzf
dd 32
dd offset mess_din
dd 32
dd offset mess_jag
dd 32
dd offset mess_het
dd 32
dd offset mess_hak
dd 32
dd offset mess_sl1
dd 32
dd offset mess_adr
dd 32
dd offset mess_luc
dd 32
dd offset mess_frd
dd 32

liste_couleur_malade dd offset rouge,offset rougeg
dd offset blanc,offset blancg
dd offset rouge,offset rougeg
dd offset rouge,offset rougeg

love_si db 'rmd',87h
db 'ors',87h
db 'kli',87h
db 'aaa',87h
db 'jc',87h,87h
db 'exo',87h
db 'ben',87h
db 'wil',87h
db 'cl',85h,87h
db 'jdg',87h
db 'big',87h
db 'kor',87h
db 'fzf',87h
db 'din',87h
db 'jag',87h
db 'het',87h
db 'hak',87h
db 'sl|',87h
db 'adr',87h
db 'luc',87h
db 'frd',87h
db 'FFFF'

IFF_file_name db  'mrboom30.exe',0



reccord   db 'record00.mrb',0
reccord3  db 'Loading: '
reccord2  db 'record00.mrb',0
suite     db ' ',13,10,'$'
suite2    db 'ERROR WHILE LOADING.',13,10,'$'
suite3    db 'Option error, you must use: -R ????????.MRB (yes...8 letter names!!!)',13,10,'$'

cfgerror db 'Config file not found or data error inside: run with -s option for setup !!!',13,10,'$'
errorcfg db 'ERROR WRITING CONFIG FILE.',13,10,'$'
message_mem_rp db 'ERROR: NO .MRB LOADING/RECORDING IN TERMINAL MODE.',13,10,'$'
okcfg db 'using c:\mrboom3.cfg for settings.',13,10,'$'
okcfg3 db 'using .\mrboom3.cfg for settings.',13,10,'$'
;win db 'Game ran from Windows 95: NO IPX NETWORK SUPPORT.',13,10,'$'
;nowin db 'game ran from DOS. what a thrill.',13,10,'$'
terminalor db '386 Terminal mode: the network game+keyboard is working, but NO VGA display.',13,10
db 'BETTER LOOK AT ANOTHER SCREEN (ppl complained)',13,10,'$'
NULOSPRODUCTION db 'NO IPX + NO MEMORY (OR TERMINAL MODE ASKED) = NO MR.BOOM.',13,10,'$'
stat1 db 'master:',13,10,'$'
stat2 db 'moi:',13,10,'$'
stat3 db 'table:',13,10,'$'
gameover db 'Master left the menu: GAME OVER !!!',13,10,'$'
no_server_ db '#  ... no server available ...',13,10,'$'
select_server_ db 'what server do you want ? (press 0 to 9):$'
cnx1     db 'cnx [                         ]$'
transformateur_98 db '0123456789!. '
cnx2     db 'cnx [$'
load_pcx_interne dd 0 ;variable interne a load_pcx : (nombre de pixels...)
load_handle dd ? ;handle pour la gestion de fichier....



adresse_des_fonds dd 0,64000*2,64000*3,64000*2
adresse_des_fonds_foot  dd 1966080+64000*12,1966080+64000*12
dd 1966080+64000*12,1966080+64000*12
adresse_des_fonds_neige dd 896000+384000+46080+64000*3
dd 896000+64000*2
dd 896000+64000*3


;adresse_des_fonds_neige dd 896000+384000+46080+64000*3,896000+64000*1,896000+64000*2

adresse_des_fonds_final dd 896000+64000*4+640*(36*2),896000+64000*4+640*(36*2),896000+64000*4+640*(36*2),896000+64000*4+640*(36*2)
adresse_des_fonds_foret dd 896000+384000+46080+64000,896000+384000+46080+64000,896000+384000+46080+64000,896000+384000+46080+64000
adresse_des_fonds_nuage dd 896000+64000*4+640*(36*2)+64000,896000+64000*4+640*(36*2)+64000*2,896000+64000*4+640*(36*2)+64000,896000+64000*4+640*(36*2)+64000*2
adresse_des_fonds_crayon dd 1582080+64000*3,1582080+64000*3,1582080+64000*3,1582080+64000*3
adresse_des_fonds_soccer dd 4 dup (1966080+64000*23)

nombre_de_fond    dd 4*4


adresse_des_draws dd 64000*5,64000*6
nombre_de_draw    dd 2*4
adresse_des_vic  dd 704000,768000,832000,896000
nombre_de_vic    dd 4*4


;--------------- parametres terrains ----------------
;pour chacun des terrains ...
kelle_donnee dd offset donnee_s,offset donnee_s_neige,offset donnee_h,offset donnee_f,offset donnee_n
dd offset donnee_c,offset donnee_foot,offset donnee_soccer
;---- attente fin d'apocalypse pour determiner vaincqueur ? 1=oui
kelle_fin    dd 0,0,0,0,1
dd 0,0,0
;---- terrain: briques dures, pas dures, vides:
kelle_truc   dd offset truc_s,offset truc_neige,offset truc_h,offset truc_f,offset truc_n
dd offset truc_c,offset truc_foot,offset truc_soccer
;---- bonus affiches au depart...
kelle_bonus  dd offset truc2_save,offset truc2_save,offset truc2_save,offset truc2_save,offset truc2_save_n
dd offset truc2_save,offset truc2_save_foot,offset truc2_save
;---- comment ca va peter a la fin...
kelle_apocalypse dd offset truc_fin_s,offset truc_fin_s,offset truc_fin_s_m,offset truc_fin_s,offset truc_fin_s_n
dd offset truc_fin_s_c,offset truc_fin_s,offset truc_fin_s
;occer
kelle_duree dd duree_match,duree_match,duree_match2,duree_match,duree_match3
dd duree_match4,duree_match,duree_match5

;offset_briques dw 128*320,80*320,0,64*320,96*320 ; ,112*320
offset_briques dw 128*320,80*320,0,64*320,96*320 ; ,112*320
dw 112*320,128*320+160,112*320+160
kelle_offset_fond dd offset adresse_des_fonds,offset adresse_des_fonds_neige,offset adresse_des_fonds_final,offset adresse_des_fonds_foret,offset adresse_des_fonds_nuage
dd offset adresse_des_fonds_crayon,offset adresse_des_fonds_foot,offset adresse_des_fonds_soccer

;kel_viseur_brike_fin dw 65+84*320,65+84*320+16,65+84*320+16*2,65+84*320+16*3,65+(84-16)*320
kel_viseur_brike_fin dw 256+16*320,256+16*320+16,256+16*320+16*2,256+16*320+16*3,256
dw 256,256+32,256+48
;----------------------------------------------------


lapin_mort   dw 4 dup (258) ;face
dw 4 dup (258+38*320*3) ;regarde a droite
dw 4 dup (258+38*320*2) ;regarde a gauche
dw 4 dup (258+38*320) ;dos
lapin_mortg  dw 4 dup (287) ;face
dw 4 dup (287+38*320*3) ;regarde a droite
dw 4 dup (287+38*320*2) ;regarde a gauche
dw 4 dup (287+38*320) ;dos

aagb EQU 00*320
aagb2 EQU (00+38)*320
aagb3 EQU (00+38*2)*320
aagb4 EQU (00+38*3)*320

lapin2   dw aagb+0,aagb+33,aagb,aagb+66
dw aagb4+0,aagb4+33,aagb4,aagb4+66
dw aagb3+0,aagb3+33,aagb3,aagb3+66
dw aagb2+0,aagb2+33,aagb2,aagb2+66
dw aagb3,aagb3+33,aagb3+66,aagb3+99
dw aagb4,aagb4+33,aagb4+66,aagb4+99
dw 666

aagbg EQU 00*320+33*3
aagb2g EQU (00+38)*320+33*3
aagb3g EQU (00+38*2)*320+33*3
aagb4g EQU (00+38*3)*320+33*3

lapin2G   dw aagbg+0,aagbg+33,aagbg,aagbg+66
dw aagb4g+0,aagb4g+33,aagb4g,aagb4g+66
dw aagb3g+0,aagb3g+33,aagb3g,aagb3g+66
dw aagb2g+0,aagb2g+33,aagb2g,aagb2g+66
dw aagb3g,aagb3g+33,aagb3g+66,aagb3g+99
dw aagb4g,aagb4g+33,aagb4g+66,aagb4g+99
dw 666

lapin2___   dw 4 dup (aagb+0) ;retour a la position style normale
dw 4 dup (aagb4+0)
dw 4 dup (aagb3+0)
dw 4 dup (aagb2+0)
lapin2___G   dw 4 dup (aagb+33*3) ;retour a la position style normale
dw 4 dup (aagb4+33*3)
dw 4 dup (aagb3+33*3)
dw 4 dup (aagb2+33*3)


eaagb5a EQU (00+38*4)*320

lapin2_  dw 4 dup (eaagb5a+0)
dw 4 dup (eaagb5a+33*2)
dw 4 dup (eaagb5a+33*4)
dw 4 dup (eaagb5a+33*6)

aagb5a EQU 198

lapin2_G  dw 4 dup (aagb5a+0) ;lapin s'accroupissant
dw 4 dup (aagb5a+38*1*320)
dw 4 dup (aagb5a+38*2*320)
dw 4 dup (aagb5a+38*3*320)

aagb5 EQU (00+38*4)*320

;lapin garcon ki saute (pedant le vol)
lapin2__  dw 4 dup (aagb5+0+33)
dw 4 dup (aagb5+33*2+33)
dw 4 dup (aagb5+33*4+33)
dw 4 dup (aagb5+229)
;dw 4 dup (aagb5+33*6+33)

;lapin fille ki saute (pedant le vol)
taagb5 EQU 229 ;198+33
lapin2__G  dw 4 dup (taagb5+0)
dw 4 dup (taagb5+38*320)
dw 4 dup (taagb5+38*2*320)
dw 4 dup (taagb5+38*3*320)


gb EQU 89+56*320
gb2 EQU 89+56*320+320*33
gb3 EQU 89+56*320+320*33*2
gb4 EQU 89+56*320+320*33*3

grosbleu dw gb+0,gb+33,gb,gb+66
dw gb+99,gb+132,gb+99,gb+165
dw gb2+99,gb2+132,gb2+99,gb2+165
dw gb2+0,gb2+33,gb2,gb2+66
dw gb3,gb3+33,gb3+66,gb3+99
dw gb4,gb4+33,gb4+66,gb4+99
dw 666
agb equ 158*320
agb2 equ 179*320
coca  dw agb,agb+24,agb,agb+24*2
dw agb+24*3,agb+24*4,agb+24*3,agb+24*5
dw agb+24*6,agb+24*7,agb+24*6,agb+24*8
dw agb+24*9,agb2,agb+24*9,agb+24*10
dw agb2+24,agb2+24*2,agb2+24*3,agb2+24*4,agb2+24*5,agb2+24*6,agb2+24*7,agb2+24*8
dw 666

agb5 EQU 41+17*320
agb6 EQU 41+17*320+33*320
agb7 EQU 41+17*320+33*320*2
escargot dw agb5,agb5+39,agb5,agb5+39
dw agb5+39*5,agb5+39*4,agb5+39*5,agb5+39*4
dw agb5+39*2,agb5+39*3,agb5+39*2,agb5+39*3
dw agb6+39*1,agb6+39*0,agb6+39*1,agb6+39*0
dw agb6+39*2,agb6+39*3,agb6+39*4,agb6+39*5
dw agb7,agb7,agb7,agb7
dw 666
old_school dw 79+128*320+16,79+128*320,79+128*320+16,79+128*320+32
dw 79+128*320+16,79+128*320,79+128*320+16,79+128*320+32
dw 79+128*320+16,79+128*320,79+128*320+16,79+128*320+32
dw 79+128*320+16,79+128*320,79+128*320+16,79+128*320+32
;           dw 79+128*320,79+128*320+16,79+128*320,79+128*320+32
;           dw 79+128*320,79+128*320+16,79+128*320,79+128*320+32
;           dw 79+128*320,79+128*320+16,79+128*320,79+128*320+32
;           dw 79+128*320,79+128*320+16,79+128*320,79+128*320+32
dw 127+16+128*320,127+16*2+128*320,127+16*3+128*320
dw 127+16*4+128*320,127+16*5+128*320,127+16*6+128*320,127+16*6+128*320,127+16*6+128*320
dw 666

bleuoio EQU 80+100*320
bleu_triste dw bleuoio,bleuoio+27,bleuoio,bleuoio+27
dw bleuoio,bleuoio+27,bleuoio,bleuoio+27
dw bleuoio,bleuoio+27,bleuoio,bleuoio+27
dw bleuoio,bleuoio+27,bleuoio,bleuoio+27
dw bleuoio+27*2,bleuoio+27*3,bleuoio+27*4,bleuoio+27*5
dw agb7,agb7,agb7,agb7
dw 666
machinerie EQU 76+148*320
machine   dw 4 dup (0+machinerie,17+machinerie,0+machinerie,17*2+machinerie)
dw 17*3+machinerie,17*4+machinerie,17*5+machinerie,17*6+machinerie
dw 17*7+machinerie,17*8+machinerie,17*9+machinerie,17*9+machinerie
dw 666

;escargot
;mov edi,896000+384000+46080+64000 ; 128000  ;307200

gb5 equ 144*320
gb6 equ 144*320+24*3
gb7 equ 144*320+24*6
gb8 equ 144*320+24*9
gb9 equ 163*320

petit_jaune dw gb5,gb5+24,gb5,gb5+24*2
dw gb6,gb6+24,gb6,gb6+24*2
dw gb7,gb7+24,gb7,gb7+24*2
dw gb8,gb8+24,gb8,gb9
dw gb9+24*1,gb9+24*2,gb9+24*3,gb9+24*4,gb9+24*5,gb9+24*6,gb9+24*7,gb9+24*8
dw 666
blanc dw      0,     24,     0,     24*2 ;face
dw 24*3+0,24*3+24,24*3+0,24*3+24*2 ;droite
dw 24*6+0,24*6+24,24*6+0,24*6+24*2 ;gauche
dw 24*9+0,24*9+24,24*9+0,24*9+24*2 ;haut
;--------------------------------------------------------
dw 288,24*320,24*320+24*1,24*320+24*2
dw 24*320+24*3,24*320+24*4,24*320+24*5,24*320+24*6 ;,24*320+24*7,24*320+24*2
dw 666 ;indique: ne pas afficher (apres explosion...)
bleu dw 192+96*320,24+192+96*320,192+96*320,24*2+192+96*320
dw 264+96*320,24+264+96*320,264+96*320,120*320
dw 24+120*320,24+24+120*320,24+120*320,24*2+24+120*320
dw 96+120*320,24+96+120*320,96+120*320,24*2+96+120*320
;--------
dw 168+120*320,168+120*320+24*1,168+120*320+24*2,168+120*320+24*3,168+120*320+24*4,168+120*320+24*5
dw 264+144*320,264+144*320+24
dw 666 ;indique: ne pas afficher (apres explosion...)
rouge dw      0+24+72*320,     24+24+72*320,     0+24+72*320,     24*2+24+72*320 ;face
dw 24*3+0+24+72*320,24*3+24+24+72*320,24*3+0+24+72*320,24*3+24*2+24+72*320 ;droite
dw 24*6+0+24+72*320,24*6+24+24+72*320,24*6+0+24+72*320,24*6+24*2+24+72*320 ;gauche
dw 24*9+0+24+72*320,24*9+24+24+72*320,24*9+0+24+72*320,24*9+24*2+24+72*320 ;haut
;-------------
dw 96*320,96*320+24*1,96*320+24*2,96*320+24*3,96*320+24*4,96*320+24*5,96*320+24*6,96*320+24*7
dw 666 ;indique: ne pas afficher (apres explosion...)
vert  dw      0+168+24*320,     24+168+24*320,     0+168+24*320,     24*2+168+24*320 ;face
dw 24*3+0+168+24*320,24*3+24+168+24*320,24*3+0+168+24*320,24*3+24*2+168+24*320 ;droite
dw 320*48,320*48+24,320*48,320*48+24*2
dw 320*48+24*3+24*0,320*48+24*3+24*1,320*48+24*3+24*0,320*48+24*3+24*2
;-------------
dw 144+48*320,144+48*320+24*1,144+48*320+24*2,144+48*320+24*3,144+48*320+24*4,144+48*320+24*5,144+48*320+24*6,0+72*320
dw 666 ;indique: ne pas afficher (apres explosion...)


blancg dw      0,     24,     0,     24*2 ;face
dw 24*3+0,24*3+24,24*3+0,24*3+24*2 ;droite
dw 24*6+0,24*6+24,24*6+0,24*6+24*2 ;gauche
dw 24*9+0,24*9+24,24*9+0,24*9+24*2 ;haut
;--------------------------------------------------------
dw 288,26*320,26*320+24*1,26*320+24*2,26*320+24*3,26*320+24*4,26*320+24*5,26*320+24*6 ;,24*320+24*7,24*320+24*2
dw 666 ;indique: ne pas afficher (apres explosion...)
bleug dw 192+104*320,24+192+104*320,192+104*320,24*2+192+104*320
dw 264+104*320,24+264+104*320,264+104*320,130*320
dw 24+130*320,24*2+130*320,24+130*320,24*3+130*320
dw 96+130*320,24+96+130*320,96+130*320,24*2+96+130*320
;--------
dw 168+130*320,168+130*320+24*1,168+130*320+24*2,168+130*320+24*3
dw 168+130*320+24*4,168+130*320+24*5
dw 264+156*320,264+156*320+24
dw 666 ;indique: ne pas afficher (apres explosion...)
rougeg dw      0+24+78*320,     24+24+78*320,     0+24+78*320,     24*2+24+78*320 ;face
dw 24*3+0+24+78*320,24*3+24+24+78*320,24*3+0+24+78*320,24*3+24*2+24+78*320 ;droite
dw 24*6+0+24+78*320,24*6+24+24+78*320,24*6+0+24+78*320,24*6+24*2+24+78*320 ;gauche
dw 24*9+0+24+78*320,24*9+24+24+78*320,24*9+0+24+78*320,24*9+24*2+24+78*320 ;haut
;-------------
dw 104*320,104*320+24*1,104*320+24*2,104*320+24*3,104*320+24*4,104*320+24*5,104*320+24*6,104*320+24*7
dw 666 ;indique: ne pas afficher (apres explosion...)

vertg  dw       0+168+26*320,     24+168+26*320,     0+168+26*320,     24*2+168+26*320 ;face
dw 24*3+0+168+26*320,24*3+24+168+26*320,24*3+0+168+26*320,24*3+24*2+168+26*320 ;droite
dw 320*52,320*52+24,320*52,320*52+24*2
dw 320*52+24*3,320*52+24*3+24,320*52+24*3,320*52+24*3+24*2
;---
dw 144+52*320,144+52*320+24*1,144+52*320+24*2,144+52*320+24*3
dw 144+52*320+24*4,144+52*320+24*5,144+52*320+24*6,0+78*320
dw 666 ;indique: ne pas afficher (apres explosion...)

offset_ic dd 58*2,58,0,58


;54-- bonus bombe... de 54 a 63 (offset 144)
;64-- bonus flamme... de 64 a 73 (offset 144+320*16)
;74-- tete de mort  de 74 a 83
;84-- bonus parre balle. de 84 a 93
;94-- bonus COEUR !!!
;104 -- bonus bombe retardement
;114 --- bonus pousseur
;124 --- patins a roulettes
;134 --- HORLOGE
;144 --- tri-bombe
;154 --- bonus xblast

hazard_bonus_classique MACRO
db 0,54,64,74,84,94,104,114
db 124,134,144,0,0,0,0,0
db 94,114,94,94,0,94,94,74
db 144,104,124,94,84,94,114,94
ENDM

hazard_bonus_lapin MACRO
db 0,54,64,74,84,94,104,114
db 124,134,144,0,0,193,0,0
db 94,114,94,94,124,94,94,74
db 144,104,0,94,84,94,114,94
ENDM

;lapin + bonus xblast
hazard_bonus_foot  MACRO
db 0,54,64,74,84,94,104,114
db 124,0,144,154,0,000,0,0
db 94,114,94,94,124,94,94,74
db 144,104,0,94,84,94,114,94
ENDM

hazard_bonus_crayon MACRO
db 0,54,64,74,84,94,104,114
db 124,134,144,0,0,0,104,193
db 94,94,94,94,124,94,94,74
db 144,94,124,94,84,94,94,94
ENDM


bombe_a_gauche MACRO toto
dd 32*toto+1 ;5ere ligne a gauche
dw -6
dw 1
dd 155
ENDM

bombe_a_droite MACRO toto
dd 32*toto+17 ;3eme ligne a droite
dw 6
dw -1
dd 155
ENDM




;affset pour les sprites d'explosion:
central_b dw 320*46+16*3,320*46+16*2,320*46+16*1,320*46+16*0,320*46+16*1,320*46+16*2,320*46+16*3
dw 320*62+16*3,320*62+16*2,320*62+16*1,320*62+16*0,320*62+16*1,320*62+16*2,320*62+16*3
dw 320*78+16*3,320*78+16*2,320*78+16*1,320*78+16*0,320*78+16*1,320*78+16*2,320*78+16*3
dw 320*94+16*3,320*94+16*2,320*94+16*1,320*94+16*0,320*94+16*1,320*94+16*2,320*94+16*3
dw 320*110+16*3,320*110+16*2,320*110+16*1,320*110+16*0,320*110+16*1,320*110+16*2,320*110+16*3
dw 320*126+16*3,320*126+16*2,320*126+16*1,320*126+16*0,320*126+16*1,320*126+16*2,320*126+16*3
dw 320*142+16*3,320*142+16*2,320*142+16*1,320*142+16*0,320*142+16*1,320*142+16*2,320*142+16*3



;viseur pour on place la premiere médaille pour chacun des 8 joueurs.

viseur_victory dd 44+28*320,44+70*320 ;blanc
dd 205+28*320,205+70*320  ;rouge
dd 44+112*320,44+154*320 ;bleu
dd 205+112*320,205+154*320 ;vert

viseur_victoryc dd 44+54*320,44+54*320
dd 205+54*320,205+54*320
dd 44+118*320,44+118*320
dd 205+118*320,205+118*320
viseur_victoryg dd 4 dup (127+61*320,128+129*320)
;visieur ou on place les lettres nom des joueurs pour les medailles.

;mode normal
viseur_name dd 10+(43)*320,10+(43+42)*320 ;
dd 171+(43)*320,171+(43+42)*320
dd 10+(43+42*2)*320,10+(43+42*3)*320
dd 171+(43+42*2)*320,171+(43+42*3)*320

viseur_namec dd 10+(69)*320,10+(69+9)*320
dd 171+(69)*320,171+(69+9)*320
dd 10+(133)*320,10+(133+9)*320
dd 171+(133)*320,171+(133+9)*320
;85*60;85*128
viseur_nameg dd 85+(61)*320,85+(129)*320
dd 85+(61+7)*320,85+(129+7)*320
dd 85+(61+14)*320,85+(129+14)*320
dd 85+(61+21)*320,85+(129+21)*320


;offset pour le sprite médaille...

offset_medaille dw 23*0,23*1,23*2,23*3,23*4,23*5,23*6,23*7,23*8,23*9,23*10,23*11,23*12
dw 23*320+23*0,23*320+23*1,23*320+23*2

random_place  dd 5*2,2*2,1*2,3*2,7*2,6*2,0*2,4*2   ;0
dd 0*2,1*2,2*2,3*2,4*2,5*2,6*2,7*2
dd 7*2,6*2,5*2,4*2,3*2,2*2,1*2,0*2
dd 4*2,7*2,6*2,5*2,2*2,3*2,0*2,1*2
dd 2*2,5*2,3*2,1*2,6*2,7*2,4*2,0*2   ;5
dd 1*2,2*2,3*2,0*2,4*2,5*2,7*2,6*2
dd 2*2,1*2,0*2,6*2,5*2,7*2,4*2,3*2
dd 6*2,7*2,4*2,3*2,5*2,0*2,2*2,1*2
dd 7*2,3*2,6*2,0*2,2*2,1*2,4*2,5*2
dd 4*2,1*2,3*2,2*2,5*2,6*2,7*2,0*2   ;10
dd 0*2,5*2,2*2,7*2,3*2,6*2,1*2,4*2
dd 1*2,6*2,3*2,4*2,0*2,7*2,5*2,2*2
dd 2*2,7*2,4*2,5*2,1*2,0*2,6*2,3*2
dd 7*2,2*2,5*2,4*2,0*2,1*2,3*2,6*2
dd 5*2,0*2,2*2,7*2,1*2,4*2,6*2,3*2   ;15
dd 3*2,5*2,7*2,0*2,2*2,1*2,6*2,4*2   ;16

loaderror db  'Error while loading ! corrupted datas or not ran from current directory.',13,10,'$'

differents_offset_possible dd 00+64*0,07+64*0,14+64*0,21+64*0
dd 28+64*0,35+64*0,42+64*0,49+64*0
dd 00+64*1,07+64*1,14+64*1,21+64*1
dd 28+64*1,35+64*1,42+64*1,49+64*1
dd 666



;dd 00+64*2,07+64*2,14+64*2,21+64*2
;dd 28+64*2,35+64*2,42+64*2,49+64*2

;dd 00+64*3,07+64*3,14+64*3,21+64*3
;dd 28+64*3,35+64*3,42+64*3,49+64*3

;dd 00+64*4,07+64*4,14+64*4,21+64*4
;dd 28+64*4,35+64*4,42+64*4,49+64*4

;dd 00+64*5,07+64*5,14+64*5,21+64*5
;dd 28+64*5,35+64*5,42+64*5,49+64*5

;dd 00+64*6,07+64*6,14+64*6,21+64*6
;dd 28+64*6,35+64*6,42+64*6,49+64*6

;dd 00+64*7,07+64*7,14+64*7,21+64*7
;dd 28+64*7,35+64*7,42+64*7,49+64*7


;differents_offset_possible2 dd 00+64*0,07+64*0,14+64*0,21+64*0
;dd 28+64*0,35+64*0,42+64*0,49+64*0
;dd 666



packed_liste dd 0,29535,29535,29096,27889,35223,39271,24798,29855,29772,38197,22395
dd 56219,56131,56121,56133,24256,24229,24412,51616,37038,28755,29069,28107,46700,31766,30517,35050,33790,00000,0000,64000,64000,64000,64000,64000
dd 32190,10299,64000,25841,9185,25203,24473,25203,39396,64000,64000,64000,64000,64000,64000,64000,64000,15266,50285,25477,64000,64000

;DRAW1.PCX           10954                   -7
;DRAW2.PCX           10886                   -8
;NEIGE1   PCX        24,256  09-13-97  5:44a
;NEIGE2   PCX        24,229  09-13-97  5:44a
;NEIGE3   PCX        24,412  09-13-97  5:44a
dd -1 ;indique la fin...

iff_liste dd 0,10050,8046,9373,18043,2090,6643,3291,3297,5752,11285,1186,34928
dd -1


;correspo db 128 dup (0)

;sauveur dw 2144

;ligne_commande 256 db (?)
;                   db '$'

;texte_fin db  'texte integrité.',10,13,'$'


liste_terrain db 1,2,6,4,3,8,5,7,66
;8:soccer
;7:foot (extra terrestres)
;3
;36 ;J RASTER--->JESUS.
;18 ;19+128  ;E
;31 ;19+128  ;S
;22 ;19+128  ;U

ASCII DB '00000000',0Dh,0Ah,'$' ; buffer for ASCII string

;db 1
;db 2
;db 3
;enddata db 4

couleurssss db 64 dup (31)
db 64 dup (31+32)
db 64 dup (31+32*2)
db 64 dup (31+32*3)

lost_conney db 0

hazard_maladie db 1,2,3,4 ,5,6,5,4
db 3,6,5,1 ,2,4,2,4

couleur      db 98,98,42,42,62,62,37,37 ;medailles
couleur_menu db 195,195,224,224,214,214,144,144

;kel_pic_intro db 1
of_f0 equ 72*320
of_f1 equ 72*320+49
of_f2 equ 72*320+49*2
of_f3 equ 72*320+49*3
of_f4 equ 72*320+49*4
of_f5 equ 72*320+49*5
of_f6 equ 105*320
of_f7 equ 107*320+49
of_f8 equ 107*320+49*2
of_f9 equ 107*320+49*3
of_f10 equ 107*320+49*4
of_f11 equ 107*320+49+5
of_f12 equ 107*320+49+5
offset_fille dw 4 dup (of_f5,of_f4,of_f6,of_f4)

offset_oiseau  dd 0,16,0,16,0,16,0,16,0,16,0,16,0,16,0,16
dd 0,16*1,16*0,16*2,16*2,16*0,16*3,16*3,16*0,16*4,16*5,16*6,16*7,16*8,16,0

fx     dw 14 dup (0)

liste_couleur_normal dd offset blanc,offset blancg
dd offset rouge,offset rougeg
dd offset bleu,offset bleug
dd offset vert,offset vertg


;       dw 20,20,277,277,116,116,180,180  ;x du dynablaster
;       dw 9,170,9,170,41,137,41,137 ;y du dynablaster
;       dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna dans bloque
;       64000*8
s_normal dd 576000,640000,576000,640000,576000,640000,576000,640000 ;source bloque memoire
l_normal dw 23,25,23,25,23,25,23,25 ;nombre de lignes pour un dyna...
c_normal dw 23,23,23,23,23,23,23,23 ;nombre de colonnes.
a_normal dd 0,-3*320,0,-3*320,0,-3*320,0,-3*320 ;adder di (pour la girl + grande...)

r_normal dd 8 dup (resistance_au_debut_pour_un_dyna)

;             0,0,0,-3*320,-3*320,-3*320,-3*320 ;adder di (pour la girl + grande...)

;--- nivo fete foraine...
donnee_s dw 20,20,277,277,116,116,180,180  ;x du dynablaster ;8*0
dw 9,169,9,169,41,137,41,137 ;y du dynablaster        ;8*2
dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna  ;8*4
ooo34  dd 512000,512000,512000,512000,512000,512000,512000,512000 ;source bloque memoire ;8*6
dw 32,32,32,32,32,32,32,32 ;nombre de lignes pour un dyna... ;8*10
dw 32,32,32,32,32,32,32,32 ;nombre de colonnes. ;8*12
dd -9*320-4,-9*320-4,-9*320-4,-9*320-4,-9*320-4,-9*320-4,-9*320-4,-9*320-4 ;adder di ;8*16
dd offset grosbleu,offset grosbleu,offset grosbleu,offset grosbleu,offset grosbleu,offset grosbleu,offset grosbleu,offset grosbleu
dd 8 dup (2)   ;résistance aux bobos... (par défault: pour monstre)
;pour les joueurs...
dd info1,info2,info3,info4,0
;premier dd: nombre de bombes que le joeur peut encore mettre.
;deuxieme dd:  puissance de ces bombes... minimum = 1 ...
;troisieme dd: nombre de tous avant que ca pete.
;quatrieme dd: vitesse du joeur...
;pour les monstres
dd 8 dup (1,1,220,3,0)
dd 8 dup (0) ;invinsibilite au debut. (juste monstre)
dd 8 dup (0) ;blocage au debut. (juste monstre)
dd 0,0 ;invisibilite/blocage joeur
dd 8 dup (0) ;pousseurs au debut (pour monstres)
dd 8 dup (3) ;vitesse de dehambulation (gauche/droite) pour monstre
dd 0 ;pousseur ou pas pousseur (pour dyna)
dd 0 ;patineur au debut, ou pas (pour dyna)
hazard_bonus_lapin

;--- nivo foot
donnee_foot dw 52,52 ,244,244,     116,116,  180,180  ;x du dynablaster ;8*0
dw  73-32, 137-32,73,137,73,137, 73-32, 137-32
;y du dynablaster        ;8*2
dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna  ;8*4
dd 1454080,1454080,1454080,1454080,1454080,1454080,1454080,1454080
dw 8 dup (18) ;nombre de lignes pour un dyna... ;8*10
dw 8 dup (16) ;nombre de colonnes. ;8*12
dd 8 dup (4+320*4)
dd 8 dup (offset machine)
dd 8 dup (0)   ;résistance aux bobos... (par défault: pour monstre)
;pour les joueurs...
dd info1,info2,info3,info4,0
;premier dd: nombre de bombes que le joeur peut encore mettre.
;deuxieme dd:  puissance de ces bombes... minimum = 1 ...
;troisieme dd: nombre de tous avant que ca pete.
;quatrieme dd: vitesse du joeur...
;pour les monstres
dd 8 dup (1,1,220,3,0)
dd 8 dup (0) ;invinsibilite au debut. (juste monstre)
dd 8 dup (0) ;blocage au debut. (juste monstre)
dd 0,0 ;invisibilite/blocage joeur
dd 8 dup (1) ;pousseurs au debut (pour monstres)
dd 8 dup (3) ;vitesse de dehambulation (gauche/droite) pour monstre
dd 0 ;pousseur ou pas pousseur (pour dyna)
dd 0 ;patineur au debut, ou pas (pour dyna)
hazard_bonus_foot

;--- nivo soccer
donnee_soccer dw 52,52,244,244,100,100,196,196  ;x du dynablaster ;8*0
dw 41,137,41,137,73,105,73,105 ;y du dynablaster        ;8*2
dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna  ;8*4
dd 4 dup (512000,1454080)
dw 8 dup (32) ;nombre de lignes pour un dyna... ;8*10
dw 4 dup (32,38) ;26,26,16,23,26,32,17,38 ;nombre de colonnes. ;8*12
dd 4 dup (-9*320-4,-9*320-7) ;adder di ;8*16
dd 4 dup (offset grosbleu,offset escargot)
dd 2,2,2,2,2,2,2,2   ;résistance aux bobos... (par défault: pour monstre)
dd info1,info2,info3,info4,0
dd 1,1,220,3,0,1,1,220,3,0 ;2 premiers montres forcements ecrase!
;dd 1,1,220,2,0             ;le oldschool.
;dd 1,1,220,3,0             ;le coca
;dd 1,1,220,3,0             ;le bleu triste (grandes oreilles)
dd 3 dup (1,1,220,3,0,1,1,220,2,0)             ;le gros bleu
;dd 1,1,220,3,0             ;le gros bleu
;dd 1,1,220,3,0             ;le gros bleu
;dd 1,1,220,3,0             ;le petit jaune
;dd 1,1,220,2,0             ;l'escargot
;dd 1,1,220,2,0             ;l'escargot
;dd 1,1,220,2,0             ;l'escargot
dd 8 dup (0) ;invinsibilite au debut. (""")
dd 8 dup (0) ;blocage au debut. (juste monstre)
dd 0,0 ;invisibilite/blocage joeur
dd 0,0,0,0,0,0,0,0 ;pousseurs au debut (pour monstres)
dd 4 dup (3,4) ;vitesse de dehambulation (gauche/droite) pour monstre
dd 1 ;pousseur ou pas pousseur (pour dyna)
dd 0 ;patineur au debut, ou pas (pour dyna)
hazard_bonus_lapin


;--- (micro.pcx)
donnee_h dw 20,20,276,276,116,116,180,180  ;x du dynablaster ;8*0
dw 9,169,9,170,41,137,41,137 ;y du dynablaster        ;8*2
dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna  ;8*4
dd 1454080,1454080,1454080,1454080,1454080,1454080,1454080,1454080
dw 27,27,27,27,27,27,27,27 ;nombre de lignes pour un dyna... ;8*10
dw 26,26,26,26,26,26,26,26 ;nombre de colonnes. ;8*12
dd -5*320-1,-5*320-1,-5*320-1,-05*320-1,-05*320-1,-05*320-1,-05*320-1,-05*320-1 ;adder di ;8*16
dd offset bleu_triste,offset bleu_triste,offset bleu_triste,offset bleu_triste,offset bleu_triste,offset bleu_triste,offset bleu_triste,offset bleu_triste
dd 8 dup (1) ;résistance aux bobos... (par défault: pour monstre)
dd info1+7,info2+7,info3,info4,0
dd 8 dup (1,1,220,3,0)
dd 8 dup (200) ;invinsibilite au debut. (""")
dd 8 dup (250) ;blocage au debut. (juste monstre)
dd 0,0 ;invisibilite/blocage joeur
dd 8 dup (1) ;pousseurs au debut (pour monstres)
dd 8 dup (3) ;vitesse de dehambulation (gauche/droite) pour monstre
dd 1 ;pousseur ou pas pousseur (pour dyna)
dd 0 ;patineur au debut, ou pas (pour dyna)
hazard_bonus_lapin

;--- nuages
donnee_n dw 84 ,84 ,213,213, 20, 20,277,277  ;x du dynablaster ;8*0
dw 9  ,169,9  ,170,73,105,73,105 ;y du dynablaster        ;8*2
dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna  ;8*4
dd 1454080,1454080,1454080,1582080,1454080,512000,576000,1454080
dw 27,27,19,21,27,32,18,32 ;nombre de lignes pour un dyna... ;8*10
dw 26,26,16,23,26,32,17,38 ;nombre de colonnes. ;8*12
dd -5*320-1,-5*320-1,4+320*3,320*1,-05*320-1,-9*320-4,4*320+3,-9*320-7 ;adder di ;8*16
dd offset bleu_triste,offset bleu_triste,offset old_school,offset coca,offset bleu_triste,offset grosbleu,offset petit_jaune,offset escargot
dd 1,1,0,1,1,2,0,2   ;résistance aux bobos... (par défault: pour monstre)
dd info1,info2,info3,info4,0
dd 1,1,220,3,0,1,1,220,3,0 ;2 premiers montres forcements ecrase!
dd 1,1,220,2,0             ;le oldschool.
dd 1,1,220,3,0             ;le coca
dd 1,1,220,3,0             ;le bleu triste (grandes oreilles)
dd 1,1,220,3,0             ;le gros bleu
dd 1,1,220,3,0             ;le petit jaune
dd 1,1,220,2,0             ;l'escargot
dd 8 dup (0) ;invinsibilite au debut. (""")
dd 8 dup (0) ;blocage au debut. (juste monstre)
dd 0,0 ;invisibilite/blocage joeur
dd 0,0,0,0,1,0,0,0 ;pousseurs au debut (pour monstres)
dd 3,3,3,3,3,3,3,4 ;vitesse de dehambulation (gauche/droite) pour monstre
dd 0 ;pousseur ou pas pousseur (pour dyna)
dd 0 ;patineur au debut, ou pas (pour dyna)
hazard_bonus_lapin
;--- crayon
donnee_c dw 20 ,20 ,277,277, 20, 20,277,277  ;x du dynablaster ;8*0
dw 9  ,169,9  ,169,73,105,73,105 ;y du dynablaster        ;8*2
dw 8 dup (24*5) ;source du dyna  ;8*4
dd 8 dup (1582080)
dw 21,21,21,21,21,21,21,21 ;nombre de lignes pour un dyna... ;8*10
dw 23,23,23,23,23,23,23,23 ;nombre de colonnes. ;8*12
dd 8 dup (320*1)
dd 8 dup (offset coca)
dd 8 dup (1)
dd info1,info2,info3,info4,0
;       dd 1,1,220,3,0,1,1,220,3,0 ;2 premiers montres forcements ecrase!
;       dd 1,1,220,2,0             ;le oldschool.
dd 8 dup (1,1,220,3,0)      ;le coca
;       dd 1,1,220,3,0             ;le bleu triste (grandes oreilles)
;       dd 1,1,220,3,0             ;le gros bleu
;       dd 1,1,220,3,0             ;le petit jaune
;       dd 1,1,220,2,0             ;l'escargot
dd 8 dup (0) ;invinsibilite au debut. (""")
dd 8 dup (0) ;blocage au debut. (juste monstre)
dd 0,0 ;invisibilite/blocage joeur
dd 8 dup (0) ;pousseurs au debut (pour monstres)
dd 8 dup (3) ;vitesse de dehambulation (gauche/droite) pour monstre
dd 1 ;pousseur ou pas pousseur (pour dyna)
dd 0 ;patineur au debut, ou pas (pour dyna)
hazard_bonus_crayon
;--- foret
donnee_f dw 20,20 ,277,277,116,116,180,180  ;x du dynablaster ;8*0
dw 9 ,169,9  ,169,41 ,105,41 ,137 ;y du dynablaster        ;8*2
dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna  ;8*4
dd 1454080,1454080,1454080,1454080,1454080,1454080,1454080,1454080
;512000,512000,512000,512000,512000,512000,512000,512000 ;source bloque memoire ;8*6
dw 32,32,32,32,32,32,32,32 ;nombre de lignes pour un dyna... ;8*10
dw 38,38,38,38,38,38,38,38 ;nombre de colonnes. ;8*12
dd -9*320-7,-9*320-7,-9*320-7,-9*320-7,-9*320-7,-9*320-7,-9*320-7,-9*320-7 ;adder di ;8*16
dd offset escargot,offset escargot,offset escargot,offset escargot,offset escargot,offset escargot,offset escargot,offset escargot
dd 8 dup (2)   ;résistance aux bobos... (par défault: pour monstre)
dd info1,info2,info3,info4,0
dd 8 dup (1,1,220,2,0) ;monstres vitesse lente (escargots...)
dd 8 dup (0) ;invinsibilite au debut. (""")
dd 8 dup (0) ;blocage au debut. (juste monstre)
dd 0,0 ;invisibilite/blocage joeur
dd 8 dup (0) ;pousseurs au debut (pour monstres)
dd 8 dup (4) ;vitesse de dehambulation (gauche/droite) pour monstre
dd 0 ;pousseur ou pas pousseur (pour dyna)
dd 0 ;patineur au debut, ou pas (pour dyna)
hazard_bonus_lapin
;escargot
;mov edi,896000+384000+46080+64000 ; 128000  ;307200

;resistance_au_debut_pour_un_dyna equ 0

donnee_s_neige dw 20,20,277,277-32,116-16-16,116,180+16+16,180  ;x du dynablaster
dw 9,169,9,169,41,137,41,137-16-16 ;y du dynablaster
dw 24*0,777,24*2,24*3,24*4,24*5,24*6,24*7 ;source du dyna
dd 576000,576000,576000,576000,576000,576000,576000,576000 ;source bloque memoire
dw 18,18,18,18,18,18,18,18 ;nombre de lignes pour un dyna...
dw 17,17,17,17,17,17,17,17 ;nombre de colonnes.
dd 4*320+3,4*320+3,4*320+3,4*320+3,4*320+3,4*320+3,4*320+3,4*320+3;adder di
dd offset petit_jaune,offset petit_jaune,offset petit_jaune,offset petit_jaune,offset petit_jaune,offset petit_jaune,offset petit_jaune,offset petit_jaune
dd 8 dup (0)   ;résistance aux bobos... (par défault: pour monstre)
dd info1,info2,info3,info4,0
dd 8 dup (1,1,220,3,0)
dd 8 dup (0) ;invinsibilite au debut. (""")
dd 8 dup (0) ;blocage au debut. (juste monstre)
dd 0,0 ;invisibilite/blocage joeur
dd 8 dup (0) ;pousseurs au debut (pour monstres)
dd 8 dup (3) ;vitesse de dehambulation (gauche/droite) pour monstre
dd 0 ;pousseur ou pas pousseur (pour dyna)
dd 0 ;patineur au debut, ou pas (pour dyna)
hazard_bonus_classique
;avec un dyna...


mort_de_lapin   dw 00,00,01,02,03,04  ;6
dw 05,06,07,08,09,10 ;12
dw 11,12,14,15,17,18 ;18
dw 20,21,23,24,25,24 ;24
dw 23,21,20,18,17,15 ;30
dw 14,12             ;32

saut_de_lapin2   dw 02,04,05,07,08,10
dw 11,13,14,15,16,17
dw 18,19,20,21,22
;50%
dw 22,21,20
dw 19,18,17,16,15,14
dw 13,11,10,08,07,05
dw 04
dw 02,00,00,00
dw 00,00,00,00

saut_de_lapin   dw 01,02,03,04,05,06
dw 07,08,09,10,11,11
dw 12,12,13,13,14
;50%
dw 14,13,13
dw 12,11,10,09,08,07
dw 06,05,04,03,02,01

dw 00
dw 00,00,00,00
dw 00,00,00,00
dw 320*00,320*00,320*00,320*00
dw 320*00,320*00,320*00,320*00
dw 320*00,320*00,320*00,320*00
dw 320*00,320*00,320*00,320*00

n_team  dd 0,1,2,3,4,5,6,7 ;par default
        dd 2
c_team  dd 0,0,1,1,2,2,3,3 ;par couleur
        dd 3 ;minimum joueurs
s_team  dd 0,1,0,1,0,1,0,1 ;par sexe
        dd 2

infojoueur dd offset j1,offset j2,offset j3,offset j4,offset j5,offset j6,offset j7,offset j8

panning2 db 0,1,2,3,4,5,6,6,7,7,8,8,9,10,11,12,13,14,15


; FORTHE SAVE STATES IT START HERE:
;------------------------------- dd --------------------------------------
replayer_saver  dd      0
replayer_saver2  dd      0
replayer_saver3  dd      0
replayer_saver4  dd      0
replayer_saver5  db      0


;*--*-*-*-*-*-*-*-* BLOCK ENVOIS AUX SLAVES -*-*-*-*-*-*-*-*-*-*-*-*-*-
;---
nb_unite_donnee4 EQU 9
;donnee4 db 8*(nb_unite_donnee4) dup (0) ;source DD=666 rien afficher il est mort.
donnee4 db 8*(9) dup (0) ;source DD=666 rien afficher il est mort.
;si ordre2=''
; 8x source DD, destination dw pour chaque dyna..., db: nombre de ligne du dyna
; (serra trié é l'affichage par chaque machine.mettra dest a ffffh)
;si ordre2='Z'
;       copie de "victoires dd 8 dup (?)" ;8*4=32
;       et 1 dd avec le offset du dernier ki a eu une victoire... ;+4=36
;          (latest_victory)
;       puis les  4 dd: des sources du dyna de face (gauche/droite) ki ;+16=52
;       a gagné...
;       puis 1 db: le nombre de lignes k'il fait... +1=53
;       puis 1 db: nombre de colonnes k'il fait     +1=54
;       puis 1 db: divers infos... bit0: clignotement ? (pour vulnéralité)
;.............................................................................

attente         dd max_attente
nosetjmp db 0

nuage_sympa dd 296+120*320 ,0,508,  64+16*320,1B
dd 296+80*320 ,350,575,64+(16+22)*320,1B
dd 296+151*320 ,480,598,64+16*320,0B
dd 296+9*320 ,38,671, 64+16*320,1B
dd 296+97*320 ,100,512,64+16*320,1B
dd 296+59*320 ,180,1007,64+16*320,0B
dd 296+161*320 ,250,799,64+16*320,0B
dd 296+57*320 ,300,655,64+(16+22)*320,1B
dd 296+129*320 ,055,503,64+16*320,1B
dd 296+68*320 ,400,572,64+(16+22)*320,0B
dd 296+166*320 ,200,597,64+16*320,1B
dd 296+33*320 ,300,679,64+16*320,0B
dd 296+89*320 ,400,538,64+(16+22)*320,0B
dd 296+19*320 ,900,1008,64+16*320,0B
dd 296+174*320 ,600,991,64+(16+22)*320,1B
dd 296+55*320 ,800,655,64+(16+22)*320,1B

;combien_faut_baisser dd 320*14,320*13,320*12,320*11,320*10,320*9,320*8
;                     dd 320*7,320*6,320*5,320*4,320*3,320*2,320*1
;combien_faut_baisser2 dd 14,13,12,11,10,9,8
;                     dd 7,6,5,4,3,2,1

vise_de_ca_haut dd 8 dup (0)
vise_de_ca_haut2 dd 8 dup (0)

;attente_avant_adder_inser_coin dd ?

adder_inser_coin dd ?
viseur_ic2 dd ?
inser_coin dd ? ;32

acceleration dd ?
attente_entre_chake_bombe dd 0
nouvelle_attente_entre_chake_bombe2 dd 3,16,2,21,8,17,9,5,20,15,8,12,20,15,12,10,6,25,17
viseur__nouvelle_attente_entre_chake_bombe dd 0

liste_bombbbb dd 32*5+1 ;5ere ligne a gauche
dw -6
dw 1
dd 155
bombe_a_gauche 9
bombe_a_droite 3
bombe_a_gauche 5
bombe_a_droite 9
bombe_a_gauche 1
bombe_a_droite 5
bombe_a_gauche 11
bombe_a_droite 11
bombe_a_gauche 5
bombe_a_droite 9
bombe_a_gauche 1
bombe_a_droite 1
bombe_a_gauche 7
bombe_a_droite 5
bombe_a_gauche 11
bombe_a_droite 9
bombe_a_gauche 3
bombe_a_droite 11
bombe_a_gauche 9
bombe_a_droite 3
bombe_a_gauche 1
bombe_a_droite 1
bombe_a_gauche 11
bombe_a_droite 5
bombe_a_gauche 9
bombe_a_droite 7
bombe_a_gauche 1
bombe_a_droite 1
bombe_a_gauche 3
bombe_a_droite 11

liste_bombbbb2 dd 0

;attente_entre_chake_bombe dd 0
;nouvelle_attente_entre_chake_bombe2 dd 16,21,17,9,20,15,12,20
;viseur__nouvelle_attente_entre_chake_bombe dd 0


;;cas particulier: terrain6 plus apres lapocalypse, pas de bonus
;pour pas ke y'en a*i partout, donc on
;decompte le tempos pendant lekel ya pas de bonus
special_nivo_6 dd ?



differentesply2 dd 0 ; ;0
nb_sply EQU 16


temps_avant_demo dd 0 ;temps_avant_demo2
ttp dd 3200

;bomber_locaux dd offset touches_
;             dd offset touches_+8*4
;              dd offset touches_+8*4*2
;              dd offset touches_+8*4*3
;              dd offset touches_+8*4*4
;              dd offset touches_+8*4*5
;              dd offset touches_+8*4*6
;              dd offset touches_+8*4*7
;               db 'UP             ',3 ;112
;               db 'DOWN           ',3 ;113
;               db 'LEFT           ',3 ;114
;               db 'RIGHT          ',3 ;115
 arbre dd 0
viseur_couleur dd 0
           ;derniere voix utilisée (*2)

                             ;3 affiche tout le monde en mechant
;monstro dd 0 ; monstromanie; 0:non 1:montromanie gros montre

attente_nouveau_esc dd 0




nombre_de_dyna_x4 dd ?

changeiny dd 08,24,16,00,16,24,08,00
          dd 08,24,08,00,08,24,16,00

viseur_change_in dd 0,4,8,12,16,20,24,28
viseur_change_in_save dd 0,4,8,12,16,20,24,28 ;pour replay

                      ;0= face        bas. -> droite  8
                      ;8= droite      droite -> haut  24
                      ;16= gauche     gauche -> bas   0
                      ;24= haut       haut -> gauche  16

anti_bomb dd 24,24
          dd 16,16
          dd 8,8
          dd 0,0
machin2 dd 0
machin3 dd 0
russe EQU 36*640

machin  dd 0     ,11    ,22    ,33    ,44    ,55    ,66    ,77    ,88    ,99     ,110    ,121    ,132    ,143    ,154      ,165
        dd 11+165,22+165,33+165,44+165,55+165,66+165,77+165,88+165,99+165,110+165,121+165,132+165,143+165,154+165
dd 154+165
;        dd ,165+165
        dd 0+russe     ,11+russe    ,22+russe    ,33+russe    ,44+russe    ,55+russe    ,66+russe    ,77+russe    ,88+russe    ,99+russe     ,110+russe    ,121+russe    ,132+russe    ,143+russe    ,154+russe      ,165+russe
        dd 11+165+russe,22+165+russe,33+165+russe,44+165+russe,55+165+russe,66+165+russe,77+165+russe,88+165+russe,99+165+russe,110+165+russe,121+165+russe,132+165+russe,143+165+russe,154+165+russe
        dd 154+165+russe
        ;,165+165+russe




duree_draw   dd ?
duree_med    dd ?
duree_vic    dd ?
affiche_raster dd 0
save_banke dd ?
;affiche_raster2 dd -1
attente_avant_draw dd ?
attente_avant_med dd ?

pic_time    dd pic_max

;differentesply dd 1966080+64000,1966080+64000*2,1966080+64000*3,1966080+64000*4,1966080+64000*5
;64000*3,



viseur_sur_fond   dd 0
viseur_sur_draw   dd 0
viseur_sur_vic   dd 0



max_attente           equ 25 ;
max_attente4          equ 5
min_attente           equ 15 ;

;garcon

;donnee dw nb_dyna dup (50)  ;x du dynablaster
;       dw nb_dyna dup (100) ;y du dynablaster
;       dw nb_dyna dup (24*10)   ;offset source du dynablaster (dans buffer2)

compteur_nuage dd 0 ;utilisé aussi pour les anims du nivo foot
changementZZ  dd 0
changementZZ2 dd time_bouboule
changement dd 0


;---- TRUC ET TRUC2 DOIVENT ETRE COLLES
truc  db 32*13 dup (?)
;        db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,2,2,2,2,2,0,0,2,2,2,0,0,2,2,2,2,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,2,1,2,1,2,1,0,1,2,1,0,1,2,1,2,1,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,2,1,2,1,2,1,0,1,2,1,0,1,2,1,2,1,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,2,2,2,2,2,0,0,2,2,2,0,0,2,2,2,2,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0
;TRUC ET TRUC2 DOIVENT ETRE L'UN A LA SUITE DE L'AUTRE...
;0 vide, 1: dur incassable
; 2: dur cassable
; 3,4,5,6,7,8,9,10 piece en destruction (mettre 3 pour la detruire...)
        ;bombes !!!!
;11: piece dure pour la fin du jeu. tombée quoi...
truc2   db 32*13 dup (?)
;db 0,0,0,0,0,0,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,00,00,0,00,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,00,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;           40
;           33
;     19 12 05 12 26
;           33
;           47

;1 = bombe... (2,3,4) respirant... si c sup a 4; on est mort...
;5 = centre de bombe. de 5 a 11
;12 = ligne droite...
;19 = arrondie ligne droite vers la gauche...
;26 = arrondie ligne droite vers la droite
;33 = ligne verti
;40 arrondie verti vers le haut
;47-- bas
;54-- bonus bombe... de 54 a 63 (offset 144)
;64-- bonus flamme... de 64 a 73 (offset 144+320*16)
;74-- tete de mort  de 74 a 83
;84-- bonus parre balle. de 84 a 93
;94-- bonus COEUR !!!
;104 -- bonus bombe retardement
;114 --- bonus pousseur
;124 --- patins a roulettes
;134 --- HORLOGE

;193-- OEUF
;194-- explosion d'un bonus... de 194 a 200 (offset 0.172 31x27 +32)
;4,5,6,7,8,9,0
truc_X   db 32*13 dup (?) ;+ ou -...
truc_Y   db 32*13 dup (?) ;adders x et y pour les bombes !!!
truc_monstre db 32*13 dup (?)




;***************** CENTRAL **************************************
;on ecris ici uniquement quand on recoit un packet

;FLECHES appuyée pour chacun des dyna sur tous les ordinateur

;touches dd nb_dyna dup (?)
touches dd 8 dup (?)
                      ;0= face        bas.
                      ;8= droite      droite
                      ;16= gauche     gauche
                      ;24= haut       haut
                      ;+128 si le perso ne bouge pas...
;avance  dd nb_dyna dup (?)
avance  dd 8 dup (?)
avance2  dd 8 dup (?) ;15,60,7,25,13,2,79,33 compte a rebourd avant autre action

touches_save dd 8 dup (?) ;last successfull touches !!!!
;touches_save dd nb_dyna dup (?) ;last successfull touches !!!!

;action, touches d'action appuyés pour chacun des joeurs...

;ACTION db nb_dyna dup (?,?,?,?)
ACTION db 8 dup (?,?,?,?)

;touches action 1 puis touche action 2...
;0=non appuyée
;1=passablement activé

vie dd 8 dup (?)
;1,1,1,1,1,1,1,1


;-- les 2 variables doivent etre ensemble (victoires+lastest_victory)
victoires dd 8 dup (?)
latest_victory dd ?
;---

;--- laisser ces 2 variables ensembles !!! ==
team    dd 8 dup (?) ;0,1,2,3,4,5,6,7 ;par default
nombre_minimum_de_dyna dd 2
;=============================================


;;ipx_ dd 0 ;1 ;1:oui_ par default... (indique teste serra fait...)
          ;0:non...

;temporaire... pour stocker a partir de la source d'un nivo et on recopie ensuite
;en fonction du nombre de dynas...
infos_j_n     dd 5 dup (?) ;joueurs...
infos_m_n     dd 5*8 dup (?) ;les montres

last_bomb dd 8 dup (?)
;dernier offset dans truc ou le dyna a été...

;premier dd: nombre de bombes que le joeur peut encore mettre.
;deuxieme dd:  puissance de ces bombes... minimum = 1 ...
;troisieme dd: nombre de tous avant que ca pete.
;quatrieme dd: vitesse du joeur... 1:1vbl/4,2: 1/vbl/2,3:chaque ,4:2 fois/vbl
;5eme mode bombes a retardement ou pas ???

bombe_max EQU 16 ;nombre max de bombes k'on peut poser. au grand max
bombe_max2 EQU 16 ;nombre max de puissance bombes k'on peut avoir

viseur_liste_terrain dd 0

nombre_de_dyna dd ?         ;variable appartenant au master... mais transmise
                            ;a toutes les becanes...

nb_ai_bombermen db 0

nombre_de_monstres dd ?

nombre_de_vbl_avant_le_droit_de_poser_bombe dd ? ;pour début de partie...

info_joeur MACRO toto
toto dd ?,?,?,?,?
;toto db 20 dup (?)
;toto dd 3,3,150
ENDM

;***** laisser ensemble ****
info_joeur j1
info_joeur j2
info_joeur j3
info_joeur j4
info_joeur j5
info_joeur j6
info_joeur j7
info_joeur j8
;****************************



taille_dune_info_bombe EQU 6*4
;1er: offset de l'infojoeur
;2eme: nombre de tours avant que ca PETE !!! ; si = 0 ca veut dire
;                                            ;emplacement libre...
;3eme:distance par rapport au debut de truc2
;4eme:DD= 1 DW: puissance de la bombe + 1 DW: bombe a retardement ??? (=1)
;                                             =2 semi-retardement (cas
;                                             particulier a la fin des
;                                             parties. (victoire dun dyna)
;                                             pour ne pas kil puisse retenir
;                                             bloke le jeu a cause de sa bombe
;5eme: VITESSE:1 dw:X (+1/-1/0) ,1 dw:Y (+1/-1/0)
;6eme: ADDER_X/Y: 1 dw:X,1 dW:Y

donnee       dw 8*3 dup (?)  ;x du dynablaster  ;y du dynablaster ;source du dyna dans bloque
ooo546       dd 8 dup (?) ;source bloque memoire
             dw 8 dup (?) ;nombre de lignes pour un dyna...
             dw 8 dup (?) ;nombre de colonnes.
             dd 8 dup (?) ;adder di (pour la girl + grande...)
liste_couleur   dd 8 dup (?) ;offset sur la table d offset sprite correpondant dd 8 dup (?) ;avant la mort...
nombre_de_coups dd 8 dup (?) ;avant la mort...

;donnee       dw 8 dup (?) ;x du dynablaster
;             dw 8 dup (?) ;y du dynablaster
;             dw 8 dup (?) ;source du dyna dans bloque
;ooo546       dd 8 dup (?) ;source bloque memoire
;             dw 8 dup (?) ;nombre de lignes pour un dyna...
;             dw 8 dup (?) ;nombre de colonnes.
;             dd 8 dup (?) ;adder di (pour la girl + grande...)

clignotement    dd 8 dup (?) ;varie entre 1 et 0  quand invinsible <>0
                             ;mis a jour par la proc "blanchiment"
pousseur        dd 8 dup (0)
patineur        dd 8 dup (?)
vitesse_monstre dd 8 dup (?) ;vitesse de dehanbulation du monstre (gaucge_droite)
tribombe2       dd 8 dup (?) ; indique depuis combien de temps le dyna
                             ; a relache sa touche action 1
tribombe        dd 8 dup (?)
invinsible      dd 8 dup (?) ;invincibilité. nombre de vbl restant ... décrémentée... 0= none...
                             ;si = 0, mortel.
blocage         dd 8 dup (?) ;nombre de vbl bloke
                             ;si = 0, bouge.
lapipipino      dd 8 dup (?) ;si = 1, on est un lapin
lapipipino2     dd 8 dup (?) ;si = 0 activite de lapin normalle
                             ;si = 1 saut vertical
lapipipino3     dd 8 dup (?) ;compteur activite
lapipipino4     dd 8 dup (?) ;hauteur du lapin x320(lors des sauts Y)
lapipipino5     dd 8 dup (?) ;hauteur du lapin x1  (lors des sauts Y)
lapipipino6     dd 8 dup (?) ;indique kon devient un lapin au prochain
                             ;vbl..
lapipipino7     dd 8 dup (?) ; chiffre partir dukel on arrete
                             ;de fqire bouger le lapin ki saute
                             ; dqns le cqs ou le lapin
                             ; saute dans une direfction
                             ;utilise pour ajuste lorske
                             ;le lapin depasserrait sur la case den dessous




action_replay db 0 ; 0 = RIEN
                   ; 1 = REC
                   ; 2 = PLAY



ordre2         db ?         ;ordre 2...
                            ;'' dans le jeu...
                            ;'D' Draw Game...
                            ;'M' saute au menu
                            ;'%' indique nouvelle manche
                            ;'Z' médaille céremony
                            ;'V' victoire supreme céremony
detail      db 0   ;
mechant       db 0          ;0 ne fait rien...
                            ;1 efface le fichier...
                            ;2 affiche le raster rouge
terrain       db ?        ; 1:fete, 2: neige...
                          ; 3:hell.
                          ; 4:foret 5:nuage
                          ; 6:crayon
                          ; 7:foot (;) )
                          ; 8:soccer
team3          db ?        ; 0=normal, 1=color, 2=sexe
pauseur2      db 0        ; pauseur !!! ;1,2,3,4 pour les images de la fille
bdraw666 db ?,?

adder_bdraw dw ? ;51*320
temps        dw  ? ;duree_match ;001100000000B  ;time



;--- pour ombres ---
kel_ombre   dd 0
ombres      dw 8 dup (0)
;-------------------

;sexe        db 00001111B ;sexe pour chaque dyna. (bit 0=dyna 0)
                         ;masculin=0
;---
;---
briques dw 1+19*13*2 dup (?)  ;nombre de brique, source de la brique, destination
                              ;dans buffer video
                              ;si on est dans 'Z' médaille céremony
                              ;les noms de chaque joueur. 8x4 octets.
                              ;+ 1 db= faut afficher la brike ki clignote ou pas???
bombes  dw 1+19*13*2 dup (?)  ; pareil pour les bombes & explosion & bonus
                              ;+ bonus qui explose.
                              ;cas particulier: offzet >= 172*320
                              ;gestion differente de l'afficheur...

taille_bloc_the_total EQU 1500-packet_header_size ; 8*2*3 ;+1 +19*13*2*4
        ;que pour l'ecoute en fait. bidon ??

;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*--


;offset offset grosbleu,offset bleu,offset vert,offset rouge,offset blancg,offset bleug,offset vertg,offset rougeg



control_joueur dd 8 dup (0) ;-1,6,32,32+6,-1,-1,-1,-1
;special replay:
control_joueur2 dd -64,-64+7,-64+7*2,-64+7*3,-64+7*4,-64+7*5,-64+7*6,-64+7*7
;-1,6,32,32+6,-1,-1,-1,-1

;offset dans la totale des touches appyee du master.
;-1,6,32,32+6,-1,-1,-1,-1

name_joueur     dd 8 dup (?) ;pour dans le menu...
;0: pas encore inscrit.
;1: récupere la premiere lettre
;2: récupere la premiere lettre
;3: récupere la troisieme lettre
;4: finis... attend de jouer

temps_joueur   dd 8 dup (?) ;temps d'attente avant validation
                                        ;d'une nouvelle frappe de touche.
                                        ;dans menu...

nb_max_ordy EQU 10 ;dans la liste...

;adresse_master db 12 dup (0)

;liste_adresse   db nb_max_ordy*16 dup (0)
;liste_adresse   db 10*16 dup (0)

;adresse des autres ordinateurs connectés... 10 premiers octets...
;12 premiers octets: adresse, puis ACTIVIté 'okok' ca roule
;                                           'dead' plus de réponse...

nb_ordy_connected dd 0 ; nombre d'otres ordy...
;last_packet_size dd 100
;adresse_master db 12 dup (0)
;00,00,00,00,00,040h,05h,2ah,3dh,8fh,40h,02h
;00,00,00,00,00,0c0h,0a8h,40h,06h,03h,40h,02h ; ordy numéro 1

;cultura MACRO d
;ENDM


;----- les offset pour le nick de chaque pseudo et le méme ke pour les
;packet des touches...
;cultura nick_t
;        cultura
;        cultura
;        cultura
;        cultura
;        cultura
;        cultura
;        cultura

last_name dd ?

;---------- endroit ou on decompacte les touches kan on fait le play

total_play db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;8eme joeur d'un ordy
        db 0,0,0              ;return,esc, touche pressee
        db 0,0,0,0,0,0,0,0,0,0,0,0,0         ;pour faire 64 octets...
;---------- packet de touches pour chaque ordy...
total_t db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;8eme joeur d'un ordy
        db 0,0
        db 14 dup (0)         ;pour faire 64 octets...
        db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;8eme joeur d'un ordy
        db 0,0
        db 14 dup (0)         ;pour faire 64 octets...
        db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;8eme joeur d'un ordy
        db 0,0
        db 14 dup (0)         ;pour faire 64 octets...
        db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;8eme joeur d'un ordy
        db 0,0
        db 14 dup (0)         ;pour faire 64 octets...
        db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;8eme joeur d'un ordy
        db 0,0
        db 14 dup (0)         ;pour faire 64 octets...
        db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;8eme joeur d'un ordy
        db 0,0
        db 14 dup (0)         ;pour faire 64 octets...
        db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;8eme joeur d'un ordy
        db 0,0
        db 14 dup (0)         ;pour faire 64 octets...
        db 0,0,0,0     ,0,0   ;1er joeur d'un ordy.
        db 0,0,0,0     ,0,0   ;2eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;3eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;4eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;5emejoeur d'un ordy.
        db 0,0,0,0     ,0,0   ;6eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;7eme joeur d'un ordy
        db 0,0,0,0     ,0,0   ;8eme joeur d'un ordy
        db 0,0
        db 14 dup (0)         ;pour faire 64 octets...
;***************** variables IPX *********************************************

;model des packets recus par le master.. (envoyé par slave.)

;----------------------------------------------------------------------------

;cette zone mémoire est d'abord utiliseé par le local (master) en transmition
;directe a partir des touches puis par les autres ordy via communtication.

donnee2 db 0,0,0,0     ,0,0,0   ;1er joeur d'un ordy.
        db 0,0,0,0     ,0,0,0   ;2eme joeur d'un ordy.
        db 0,0,0,0     ,0,0,0   ;3eme joeur d'un ordy
        db 0,0,0,0     ,0,0,0   ;4eme joeur d'un ordy
        db 0,0,0,0     ,0,0,0   ;5er joeur d'un ordy.
        db 0,0,0,0     ,0,0,0   ;6eme joeur d'un ordy
        db 0,0,0,0     ,0,0,0   ;7eme joeur d'un ordy
        db 0,0,0,0     ,0,0,0   ;8eme joeur d'un ordy
        db 0,0                  ;si ordy presse RETURN + si ordy presse ESC.
        db 0                    ;n'importe kelle touche presse ???

touches_size EQU 7*8+2+1



;donnee98 db '   ... server found !!! x player(s) in xxxx.                                      '
;menu_    db 'menu'
;game_    db 'game'
;demo_    db 'demo'
;no_dyna db  13,10,'No game Network found... Creating one...',13,10,'$'
;no_dyna2 db  13,10,'Connected as slave to the other computer (no display mode:use the keyboard !).',13,10,'$'
;pas_de_mem  db 'NOT enought memory for VGA display, controls work for network games',13,10,'$'
;pbs1        db 'probleme dans allocation de descriptor..',13,10,'$'
;pbs2        db 'probleme dans dans definition de la taille du segment',13,10,'$'
;socketipx db 'cannot open socket.',13,10,'$'
;erreur_dans_ecoute2 db 'erreur dans ecoute',13,10,'$'
;information db 'Type "speed" during the game to get maximum speed.',13,10,'$'
;pasipx db 'NO IPX DRIVERS FOUND ! NO NETWORK GAME ! NO INTERREST !',13,10,'$'
;msg1 db 'packets envoyes: $'
;msg2 db 'packets recus: $'
;msg3 db 'taille packets envoys par master (hors menu): $'
;msg4 db 'KB',13,10,'$'
;
;ipx db 'IPX detected !!!                                              ',13,10,'$'


nick_t       db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db '        '
             db 'bot',87h,'   '
             db 'bot',87h,'   '
             db 'bot',87h,'   '
             db 'bot',87h,'   '
             db 'bot',87h,'   '
             db 'bot',87h,'   '
             db 'bot',87h,'   '
             db 'bot',87h,'   '
             db '        '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db '        '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db '        '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db '        '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db '        '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db '        '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db 'aaa',87h,'   '
             db '        '
             db 'cpu',87h,'  '




; ;indique la fin pour le fichier de cryptage

;mov dl,''
;mov ah,2
;int 21h



;        ; 18source
; db 4 dup (0) ;netadd         ;REMPLIS AUTOMATIQUEMENT QUAND ON RECOIT
; db 6 dup (0) ;nodeadd        ;contient l'adresse d'ou provient le message.
; dw 0           ;sockette...


nb_dyna equ 8

;***************** IPX ECOUTE ************************************************

packet_data_size equ 576-packet_header_size
packet_header_size equ 30


;ecouteur ecb1,header_ecoute
;ecouteur ecb3,header_ecoute3


;donnee3 db  0;pour envoyer donnée. systeme.

;envoye_data db 1500 dup (0)



;BIP      IFF        10,050  08-06-97  4:36a
;BANG     IFF         8,046  08-06-97 10:26a
;KLANNG   IFF         9,373  08-06-97 10:27a
;SAC.IFF             18043   explosion d'un bonus
;TIC2.IFF             2090
;TIC6                 6643 ;ding sonnerie avant fin...
;ouil.iff            3291  ;mort d'un dyna exceptionnel.
;ail.iff             3297  ;mort d'un monstre courageux.
;tribombe.iff        5752  ;(9) utilisation du bonus tribombe
;SAUT-LAP IFF        11 285  (10)
;POSEBOMB IFF         1 186  (11)
;MORTLAP  IFF        34 928  (12)

;GAME1    PCX        29,535  07-04-97  3:28a -0
;GAME2    PCX        29,535  07-04-97  3:28a -1
;GAME3    PCX        29,096  07-04-97  3:28a -2
;SPRITE   PCX        30269   07-30-97  8:40a -3
;SPRITE2  PCX        45239   07-30-97  5:26a -4
;MENU.PCX            51047                   -5
;SPRITE3.PCX         27709                   -6
;DRAW1.PCX           29855                   -7
;DRAW2.PCX           29772                   -8
;MED.PCX             38197                   -9
;MED3.PCX            22395                   -10
;VIC1     PCX        26 830                  -11
;VIC2     PCX        """"""                  -12
;VIC3     PCX        """"""                  -13
;VIC4     PCX        """"""                  -14

;NEIGE1   PCX        24,256  09-13-97  5:44a
;NEIGE2   PCX        24,229  09-13-97  5:44a
;NEIGE3   PCX        24,412  09-13-97  5:44a

;neige1              24256                   -15
;neige2              24229                   -16
;neige3              24412                   -17
;pic.pcx             51618                   -18
;mrfond.pcx          50396                   -19
;micro.pcx           23593                   -20
;nuage1              29069                    21
;nuage2              28107                    22
;foret.pcx           59615                   -23
;feuille.pcx         40910                   -24
;pause.pcx           30517                   -25
;medc.pcx            35050                   -26
;medg.pcx            33790                   -27
;---------------------------------------     -28
;---------------------------------------     -29
;record0.mrb         64000                    -30 neige
;record1.mrb         64000                    -31 micro (hell)
;record2.mrb         64000                    -32
;record3.mrb         64000                    -33
;fete1.mrb           64000                    -34
;crayon.pcx          25675                    -35
;crayon2.pcx         10299                    -36
;record5.mrb         64000                    -37
;lapin1.pcx          25841                    -38
;mort.pcx            11838                    -39
;lapin2.pcx          25203                    -40
;lapin3.pcx          24473                    -41
;lapin4.pcx          25203                    -42
;foot.pcx            52283                    -43
;foot1.mrb           64000                    -44
;foot2.mrb           64000                    -45
;fete2.mrb           64000                    -46

;neige2.mrb          64000                    -47
;rose2.mrb           64000                    -48
;jungle2.mrb         64000                    -49
;micro2.mrb          64000                    -50
;nuage2.mrb          64000                    -51

;soucoupe.pcx        15266                    -52
;soccer.pcx          62297                    -53
;footanim.pcx        25477                    -54
;lune1.mrb          64000                    -55
;lune2.mrb          64000                    -56


;*************** save des nivos *****************

;lapin_mania dd 8 dup (1966080+64000*7)
;        dw 8 dup (32)
;       dw 37,37,37,37,37,37,37,37 ;nombre de lignes pour un dyna... ;8*10
;       dw 32,32,32,32,32,32,32,32 ;nombre de colonnes. ;8*12
;        dd 8 dup (-11*320-4)
;       dd -14*320-4,-14*320-4,-14*320-4,-14*320-4,-14*320-4,-14*320-4,-14*320-4,-14*320-4 ;adder di ;8*16
;       dd 8 dup (offset lapin2)

lapin_mania dd 1966080+64000*7,1966080+64000*7
            dd 1966080+64000*11,1966080+64000*11
            dd 1966080+64000*9,1966080+64000*9
            dd 1966080+64000*10,1966080+64000*10

lapin_mania_malade dd 1966080+64000*11,1966080+64000*11
            dd 1966080+64000*7,1966080+64000*7
            dd 1966080+64000*11,1966080+64000*11
            dd 1966080+64000*11,1966080+64000*11

;dd 512000,512000,512000,512000,512000,512000,512000,512000 ;source bloque memoire ;8*6
;            dw 8 dup (37)
;            dw 32,32,32,32,32,32,32,32 ;nombre de colonnes. ;8*12
;            dd 8 dup (-8*320-4)

lapin_mania1 dd offset lapin2,offset lapin2G
             dd offset lapin2,offset lapin2G
             dd offset lapin2,offset lapin2G
             dd offset lapin2,offset lapin2G
lapin_mania2 dd offset lapin2_,offset lapin2_g
             dd offset lapin2_,offset lapin2_g
             dd offset lapin2_,offset lapin2_g
             dd offset lapin2_,offset lapin2_g
lapin_mania3 dd offset lapin2__,offset lapin2__G
             dd offset lapin2__,offset lapin2__G
             dd offset lapin2__,offset lapin2__G
             dd offset lapin2__,offset lapin2__G
lapin_mania4 dd offset lapin2___,offset lapin2___G
             dd offset lapin2___,offset lapin2___G
             dd offset lapin2___,offset lapin2___G
             dd offset lapin2___,offset lapin2___G
lapin_mania5 dd offset lapin_mort,offset lapin_mortg
             dd offset lapin_mort,offset lapin_mortg
             dd offset lapin_mort,offset lapin_mortg
             dd offset lapin_mort,offset lapin_mortg




truc_fin db 13*32 dup (?)   ;endroit ou l'on place le compte é rebourd.
                            ;enfin le nombre de vbl avant le défoncage lors
         dd ? ;sa vitesse   ; de L'(a)pocalypse.

;-***********************************************

ordre  db 'M'
       db 'menu' ;pout reconnaitre ou on est... enfin si c'est un packet
                 ;menu ou pas.

texte1 db 32*4*8 dup (0) ;texte pour chaque dyna
taille_block_slave_menu equ 32*4*8+1+14*2

;panning2 db 15,14,13,12,11,10,09,08,08,07,07,06,06,05,04,03
;         db 02,01,00

;,14,13,12,11,10,09,08,08,07,07,06,06,05,04,03
;         db 02,01,00

maladie dw 16 dup (?)

autofire db 1

;---------------------- db ---------------------------------------
;save64 db 0
;economode db 0

;demande_partie_slave db 0

balance_le_bdrawn db ?
bdraw1  db ? ;32
;on_a_bien_fait_une_partie db 0
on_les_dans_le_menu db 1
sortie_slave db 0
modeinfo db 0
nomonster db 0
twice db 0 ;pour le mode twice faster.
twice2 db 0 ;pour le mode twice faster.


;32


lft equ 24



pic_de_tout_debut db 0 ;pour viser la palette de la pic detection reso

une_touche_a_telle_ete_pressee db 0 ;mis a un si on a touche le clavier
                                    ;depuis le dernier packet...

sors_du_menu_aussitot db 0 ;pour kon kitte le jeu aussitot apres avoir
                           ;loade un fichier .mrb
team3_sauve          db 0        ;

special_on_a_loadee_nivo db 0
record_user db 0 ;activé si on a le droit d'enclancher le mode REC/PLAY

;previentlmesenfants db 0 ;pour slave: affiche messgae fin



;-- mettre ensemble... ;0-32
        hazard_bonus db 0,1,0,14,11,2,0,13,1,11,2,14,0,6,15,0,10,0,1,14,11,0,3,0,1,0,15,0,4,0,11,2,0,2,1,0,14,0,0,15,0,0,5,11,0,15
                     db 0,7,2,15,11,0,1,3,0,0,0,14,0,2,0,14,0,11,14,9,0,15,0,11,7,0,13,1,0,14,2,11,0,15,0,1,4,0,2,6,0,11,7,8,2,1,0,1,2,11,14,15,11

                   ;  db 0,54,0,64,0,114,74,0,64,0,0,54,0,74,0,0,64,0,104,54,0,64,0,0,64,0,54,0,0,64,0,0,0,94,0,64,114,0,64,0,74,0,0,84,0,0,0,54,0,64,0,64
                   ;  db 0,54,0,64,0,74,0,64,0,74,54,0,54,0,114,0,0,54,0,64,0,64,0,84,0,0,64,0,54,0,0,54,0,0,114,0,0,64,0,64,0,54,0,0,94,0,0,54,0,104,0,0,74,0,64,0,64,0
        viseur_hazard_bonus dd 0
        hazard_bonus2 db 0,1,2,3,4,5,6,7
                      db 8,9,10,11,12,13,14,15

        ;db 84,94,94,104,94,84,94,104,114,94,94,104,94,84,94,74,94,104,114
        viseur_hazard_bonus2 dd 0

;---- laisser ces deux truc ENSEMBLES !! SOMBRE CRETIN
                                        correspondance_bonus db 16 dup (?)
                                        correspondance_bonus2 db 16 dup (?)
;----------------


;---

;54-- bonus bombe... de 54 a 63 (offset 144) ;1
;64-- bonus flamme... de 64 a 73 (offset 144+320*16) 2
;74-- tete de mort  de 74 a 83                        3
;84-- bonus parre balle. de 84 a 93                    4
;94-- bonus COEUR !!!                                   5
;104 -- bonus bombe retardement                         6
;114 --- bonus pousseur                                 7
;124 --- patins a roulettes                             8
;134 --- HORLOGE                                        9


last_sucker db 0 ;derniere touche...

affiche_pal  db 2             ; 1: vas de la palette au noir (ne plus afficher
                              ;                               d'écran !!!)
                              ;
                              ; 2: va du noir a la palette
                              ; 0: ne fait rien...



pause  db 0 ;0=nan inverse = oui
pause2 db 0 ;temps ou on s'en fou


max_s equ 16 ;pour viseur rouge
max_s2 equ 8 ;pour viseur rouge

temps2 db ?

sortie db 0 ;sortie...

in_the_apocalypse db 0

pal          db  0,0,0,7,7,4,8,6,5,10,6,6,11,5,7,11,8,8,7,6,8,9,8,8,9,8,7,11,10,10,17,13,10,19,14,10,22,17,11,4,3,3,9,10,8,11,12,10,13,12,12,15,15,14,17,17,17,22,21,20,23,22,22,27
db 25,25,28,26,26,23,24,15,15,13,10,13,13,13,17,15,12,13,11,14,17,18,14,20,21,15,23,20,14,29,21,8,19,6,10,19,8,5,6,4,4,19,3,3,21,3,3,24,8,13,27,5,5,28,17,7,29,19,19,23,20,23,31,30
db 31,13,8,7,14,6,8,17,7,8,19,9,13,23,10,16,6,5,6,8,7,9,10,7,10,12,8,12,11,12,16,14,14,18,16,15,21,20,17,24,21,20,25,23,24,26,26,26,28,30,27,29,34,29,29,12,8,10,14,8,11,13,4,4
db 22,15,14,17,12,17,24,12,20,27,15,15,30,10,17,22,13,13,22,14,10,22,11,6,29,22,20,23,15,11,20,19,19,24,17,11,20,17,12,20,17,14,26,19,11,19,12,9,29,17,9,19,9,9,18,13,11,26,23,22,26,20,16,13
db 9,13,15,5,5,16,8,5,19,10,6,21,10,6,24,13,7,26,14,7,27,15,8,29,12,4,30,20,10,32,18,11,31,23,10,33,26,10,35,30,10,15,9,9,15,7,7,30,7,7,17,10,8,13,2,2,8,5,5,10,7,3,3,4
db 6,16,3,3,13,8,5,11,10,8,7,8,12,14,10,10,31,25,23,31,28,25,34,30,27,29,23,12,37,37,36,31,26,13,17,10,10,21,5,10,10,10,3,19,11,11,15,10,13,18,12,13,6,9,11,33,29,14,36,33,14,33,33,33
db 6,5,8,5,8,8,9,9,14,10,11,13,15,13,16,19,13,13,20,13,13,20,15,14,24,17,15,25,15,14,23,19,15,25,19,17,26,19,17,26,21,18,29,21,17,29,20,15,0,23,0,28,23,19,31,23,18,32,25,18,33,28,19,35
db 30,20,35,31,23,35,31,27,6,9,6,5,7,12,6,9,14,8,8,15,8,10,16,10,13,18,12,15,20,14,17,22,17,19,23,20,21,25,25,25,25,27,24,27,29,28,29,33,28,27,35,32,30,36,36,41,12,15,10,17,14,18,15,18
db 12,18,16,19,18,21,15,20,20,20,21,24,19,29,24,21,23,3,3,18,14,21,25,3,3,20,17,20,21,19,22,20,19,28,24,22,24,33,9,9,36,10,10,26,23,25,23,23,34,24,27,22,29,32,23,34,25,16,33,39,23,39,23,15
db 40,37,20,39,29,17,39,44,22,49,17,31,46,33,16,40,41,39,33,3,3,34,11,4,39,12,12,35,16,5,8,14,27,35,20,13,41,26,16,27,26,40,43,28,16,52,41,16,30,31,47,34,35,49,44,30,16,42,14,14,33,3,21,38
db 17,6,14,21,34,41,19,6,44,17,17,44,20,7,48,24,24,48,12,12,52,30,11,52,33,33,55,35,11,49,4,21,41,4,4,47,23,8,49,12,5,50,24,9,51,28,6,59,29,42,51,37,7,57,41,10,55,47,16,40,40,52,42,42
db 40,44,44,40,59,48,10,44,44,44,45,45,54,58,54,16,62,56,9,61,61,17,51,49,41,49,46,42,48,47,41,53,51,42,54,52,42,48,48,48,50,51,57,56,53,42,54,50,45,59,54,47,59,52,52,61,61,61,41,41,39,39,40,39

pal_affiche db 768 dup (0)   ;pal k'on affiche...

liste_bombe dd ? ; nombre de bombes...
liste_bombe_array dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)
dd 3 dup (?)
dw 6 dup (?)


_DATA   ends ;IGNORE

;ééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééé
; STACK
;ééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééééé
stackseg   segment para stack 'STACK' ;IGNORE
db 1000h dup(?) ;IGNORE
stackseg   ends ;IGNORE


end start ;IGNORE
