# zone extensions in grid frame (u across Amber toward ESE, v along Amber toward SSW): polygons
Z={
 "res":   ("Residential (pilot hill-row variants)", "#e8e39a", [
            [(-950,-330),(-180,-330),(-180,-180),(-130,-180),(-130,330),(-950,330)],     # west / Country Club
            [(170,-300),(560,-300),(560,320),(160,330),(150,100),(170,100)],             # Glorietta Heights
            [(760,-620),(1120,-620),(1120,-20),(760,-20)],                                  # Bay Circle
            [(-450,-1380),(380,-1380),(380,-880),(-450,-880)] ]),                         # Crown Hill (villas, slopes)
 "hs":    ("High street (pilot b_ variants)", "#f2a65a", [[(-130,-300),(130,-300),(130,420),(-130,420)]]),
 "cc":    ("City centre extension", "#c0392b", [[(-170,-880),(170,-880),(170,-300),(-170,-300)]]),
 "apt":   ("Apartment band extension", "#9b6fc3", [[(170,-880),(560,-880),(560,-300),(170,-300)],
            [(-450,-1380),(-170,-1380),(-170,-880),(-450,-880)] ]),          # Crown Hill west slope: apartments climbing
 "civ":   ("Civic + parks extension", "#4caf50", [[(-450,-880),(-170,-880),(-170,-200),(-450,-200)]]),
 "uni":   ("University campus (MUST)", "#1f9e89", [[(-950,-900),(-470,-900),(-470,-340),(-950,-340)]]),
 "grt":   ("Gritty edge extension", "#8d6e63", [[(-950,-1300),(-470,-1300),(-470,-900),(-950,-900)]]),
 "ind":   ("Industrial extension", "#607d8b", [[(-1320,-1660),(-500,-1660),(-500,-1300),(-1320,-1300)]]),
 "strip": ("Commercial strip extension", "#e91e8c", [[(380,-1340),(650,-1340),(650,-960),(380,-960)]]),
 "wf":    ("Waterfront extension", "#26a7d8", [[(380,100),(640,100),(640,430),(380,430)],
            [(-1150,300),(170,300),(170,420),(-1150,420)],                   # ocean promenade + beach
            [(180,-1760),(600,-1760),(600,-1600),(180,-1600)] ]),            # ferry landing
 "hosp":  ("Hospital campus (MUST)", "#ff5252", [[(400,-1590),(640,-1590),(640,-1400),(400,-1400)]]),
}
MUST=[("HOSPITAL","+ ER, helipad,\nambulances off 3rd St",(520,-1495)),
      ("UNIVERSITY","shares the stadium,\nstudents in the gritty edge",(-710,-620)),
      ("MUSEUM","maritime + naval air,\nat the ferry landing",(380,-1680)),
      ("COURTHOUSE","on the centre square,\nnext to the police",(110,-800))]
HERO=[("Hotel (hero)",(290,420)),("Chapel on\nthe rise (hero)",(0,-1180)),("Glorietta\nmansion (hero)",(330,-120))]
TRANS=[((-180,-560),(-60,-560),"civic|centre"),((60,-560),(200,-560),"centre|apts"),
       ((0,-460),(0,-110),"centre -> high street"),((-700,-940),(-700,-760),"gritty -> campus"),
       ((-740,-1340),(-720,-1160),"industrial -> gritty"),((300,-450),(300,-290),"apts -> houses")]
