#!/usr/local/bin/apl --script -f --
 
⍝ Unfortunately, GNU APL does not support ⍞-input in script mode very well
⍝ Therefore, this function reads STDIN directly to do it. It supports no
⍝ terminal control except backspace, and no Unicode either, which I suppose
⍝ makes it period-correct.
∇ l←ReadLine;k;z;data
        data←''         ⍝ Start out with empty string
 
        ⍝⍝⍝ Keyboard input
in:     k←1⎕fio[41]1    ⍝ Read byte from stdin
handle: →(k>127)/skip   ⍝ Unicode is not supported (Wumpus doesn't need it)
        →(k∊8 127)/back ⍝ Handle backspace
        →(k=10)/done    ⍝ Newline = Enter key pressed
        →(k<32)/in      ⍝ For simplicity, disregard terminal control entirely
        z←k⎕fio[42]0    ⍝ Echo key to stdout
        data←data,k     ⍝ Append key to data
        →in             ⍝ Go get next key
 
        ⍝⍝ Skip UTF-8 input (read until byte ≤ 127)
skip:   k←1⎕fio[41]1 ⋄ →(k>127)/skip ⋄ →handle
 
        ⍝⍝ Backspace
back:   →(0=⍴data)/in   ⍝ If nothing to delete, ignore
        z←k⎕fio[42]0    ⍝ Backspace to terminal
        data←¯1↓data    ⍝ Remove last character
        →in             ⍝ Get next key
 
        ⍝⍝ We are done, return the line as text
done:   z←10⎕fio[42]0   ⍝ Newline
        l←⎕UCS data
∇
 
⍝ Read a positive number from the keyboard, keep trying until input is valid.
∇ n←ReadNum;l
try:    l←ReadLine              ⍝ Get input
        →(l∧.∊'0123456789')/ok  ⍝ Valid number?
        ⍞←'Please enter a number: '
        →try
ok:     n←⍎l
∇
 
 
⍝ Define which rooms are adjacent
∇ c←Cave
        c←  ⊃(2 3 4)(1 5 6)(1 7 8)(1 9 10)(2 9 11)
        c←c⍪⊃(2 7 12)(3 6 13)(3 10 14)(4 5 15)(4 8 16)
        c←c⍪⊃(5 12 17)(6 11 18)(7 14 18)(8 13 19)(9 16 17)
        c←c⍪⊃(10 15 19)(11 20 15)(12 13 20)(14 16 20)(17 18 19)
∇
 
⍝ Get N random empty rooms
∇ r←n Empty rooms;z
        r←z[n?⍴z←(rooms=0)/⍳⍴rooms]
∇
 
⍝ Play the game
∇ Game;z;arrows;rooms;player;msg;adj;cur;inp;tgt
        ⎕←'∘∘∘ HUNT THE WUMPUS ∘∘∘'
        ⎕←''
        ⎕←'In search of glory and wumpus fur, you have descended into the'
        ⎕←'wumpus cave. Can you kill the wumpus, and make it out alive?'
        ⎕←''
 
 
        ⍝⍝ Initialization
        ⎕rl←(2*32)|×/⎕ts            ⍝ Initialize random seed from time
        arrows←5                    ⍝ Start with 5 arrows
        rooms←20/0                  ⍝ 20 empty rooms
        rooms[1 Empty rooms]←1      ⍝ Place wumpus in random room
        rooms[2 Empty rooms]←2      ⍝ Place two bats in random empty rooms
        rooms[2 Empty rooms]←3      ⍝ Place two pits in random empty rooms
        player←1 Empty rooms        ⍝ Put player in random empty room
 
        ⍝⍝ Player enters a room
enter:  cur←rooms[player]           ⍝ What is in the current room?
        adj←rooms[Cave[player;]]    ⍝ What is in the adjacent rooms?
        →(cur=1 2 3)/wump bat pit   ⍝ Did the player walk into something bad?
 
        ⍝⍝ Give player information about current room.
        msg←⊂'You are in room ', (⍕player), '.'
        msg←msg,⊂'You have ', (⍕arrows), ' arrows left.'
        msg←msg,⊂'Tunnels lead to: ', ,⍕Cave[player;]
        ⍝⍝ The '~ ↓' (instead of / or ↑) avoids a weird debug message here.
        msg←msg,(~1∊adj)↓⊂'You smell something terrible nearby.'
        msg←msg,(~2∊adj)↓⊂'You hear a rustling.'
        msg←msg,(~3∊adj)↓⊂'You feel a cold wind blowing from a nearby cavern.'
        ⎕←⊃msg 
 
        ⍝⍝ Move or shoot
input:  ⎕←''
        ⍞←'Do you want to _m_ove or _s_hoot? '
        inp←ReadLine ⋄ →(~(↑inp)∊'mMsS')/input
 
        ⍞←'Which room? '
        tgt←ReadNum
        →((tgt∊Cave[player;])∧'mMsS'=↑inp)/move move shoot shoot
        ⎕←'That is not possible.'
        →input
 
move:   player←tgt ⋄ →enter
shoot:  arrows←arrows-1
        →(rooms[tgt]=1)/win         ⍝ Hit the wumpus?
        ⎕←'You missed!'
        ⎕←''
        →(arrows=0)/empty           ⍝ Out of arrows?
        →(4=?4)/enter               ⍝ 25% chance of wumpus not waking up
        ⎕←'Your noise has awoken the wumpus.'
        ⎕←'He moves to another room in search of some peace and quiet.'
        ⎕←''
        z←(rooms=1)/⍳⍴rooms         ⍝ Current wumpus location
        rooms[z,Cave[z;?3]]←0 1     ⍝ Wumpus moves to adjacent room
        →enter 
 
        ⍝⍝ You hit the target
win:    ⎕←'You hear a painful roar coming from the passage.'
        ⎕←'Upon entering, you find the wumpus in a pool of its own blood.'
        ⎕←'You have won!'
        →0
 
        ⍝⍝ Out of arrows.
empty:  ⎕←'You have shot your last arrow.'
        ⍞←'Just as you realize how defenseless you are, you hear a large'
        ⍞←' beast approaching.'
        →over
 
        ⍝⍝ Player enters the room with the wumpus in it.
wump:   ⎕←'You find yourself face to face with the wumpus.'
        ⎕←'It devours you whole.'
        ⎕←''
        →over
 
        ⍝⍝ Player enters a room with a bat in it
bat:    ⎕←'You walk into a bat''s cave.'
        ⎕←'It is not amused, and carries you out.'
        ⎕←''
        player←1 Empty rooms        ⍝ Put player in random empty room. 
        →enter
 
        ⍝⍝ Player walks into a pit
pit:    ⍞←'As you confidently stride into this room, you realize it has'
        ⍞←' no floor.'
        ⎕←''
        ⍞←'You ponder the consequences of your actions as you fall to your'
        ⍞←' death.'
 
over:   ⎕←''
        ⎕←'Game over!'
 
∇
 
Game
)OFF

