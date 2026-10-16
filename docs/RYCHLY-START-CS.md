# Rychlý start česky

Tohle je **beta pro RedM a VORP**. Nejdřív ji otestuj na kopii serveru. Chyby hlásíš přes Issues → Bug report na tomto GitHubu.

## Nový server

1. V Releases stáhni instalační ZIP.
2. Rozbal složku vorp_stables do resources. Název neměň.
3. V server.cfg startuj oxmysql, vorp_core, svůj inventář a potom vorp_stables.
4. V config.lua nastav ceny, kapacity a Locale = 'cs'.
5. Do serverové konzole napiš refresh a ensure vorp_stables.
6. Připoj se, vyber postavu, dojdi ke stáji a zmáčkni G.

## Už máš VORP Stables?

1. Odpoj hráče. Zazálohuj celou databázi, resource a config.
2. Na testovací kopii spusť sql/migration-check.sql; nic nepřepisuje.
3. Přes původní inventář vyndej věci i zbraně z brašen do bezpečného úložiště.
4. Starý resource dej mimo resources a nahraď ho naším, stále pod názvem vorp_stables.
5. Nepouštěj staré SQL s DROP TABLE. Naše verze čte původní stables a horse_complements: vlastnictví, jména a výbava zůstávají.
6. Ověř svoje koně/povozy, peníze a vybavení. Věci vrať do správných nových brašen.

**Koně nekopírujeme do jiné tabulky.** Měníš resource čtoucí stejná data. Obsah brašen je zvlášť: staré ID podle modelu/postavy je nejednoznačné, pokud máš dva stejné koně. Proto věci automaticky neduplikujeme. Podrobný postup a návrat k záloze jsou v MIGRATION.md.

## Co nastavíš

Jazyk, počet koní/povozů, společný limit, gold/cash ceny, kurz zlata, procento výkupu povozu, klávesy, pískání, NPC/blipy, kamery, loading a brašny. Lokace/nabídky jsou v locations.lua, modely/výbava v shared/data.lua.

## Prodej hráči

V My Stable vyber Transfer, zadej serverové ID kupujícího a cenu v hotovosti. Kupujícímu přijde nabídka: My Stable → Incoming offers → přijmout/odmítnout. Do přijetí se vlastník ani platba nemění. Musíte být online a blízko; kupující musí být u stáje. Cena 0 je darování.

## Omezení

Vedení jezdeckého koně funguje. Vedení zapřaženého povozu je vypnuté po neúspěšném herním testu; Dismiss zůstává. Staré obsahy brašen ani všechny verze nativního Inventory V2 nejsou univerzálně otestované. Výkon závisí na prostředí serveru.
