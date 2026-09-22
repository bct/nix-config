menu_command="fuzzel"

dir="$HOME/images/screenshots"

# Buttons
screen="󰍹 Capture Desktop"
area="󰆞 Capture Area"
window="󰖲 Capture Window"
infive="󰔝 Take in 3s"
inten="󰔜 Take in 10s"

# countdown
countdown() {
	for sec in $(seq "$1" -1 1); do
		dunstify -t 1000 --replace=699 "Taking shot in : $sec"
		sleep 1
	done
}

filename() {
	date +%Y-%m-%d-%I-%M-%S.png
}

# take shots
shotnow() {
	file="$(filename)"
	hyprshot -m output -m active -o "$dir" -f "$file" || true
}

shot5() {
	countdown '3'
	file="$(filename)"
	hyprshot -m output -m active -o "$dir" -f "$file" || true
}

shot10() {
	countdown '10'
	file="$(filename)"
	hyprshot -m output -m active -o "$dir" -f "$file" || true
}

shotwin() {
	file="$(filename)"
	hyprshot -m window -m active -o "$dir" -f "$file" || true
}

shotarea() {
	file="$(filename)"
	hyprshot -m region -o "$dir" -f "$file" || true
}

if [[ ! -d "$dir" ]]; then
	mkdir -p "$dir"
fi

# Variable passed to the menu
options="$screen\n$area\n$window\n$infive\n$inten"

chosen="$(echo -e "$options" | $menu_command -p 'Take A Shot' -d)"
case "$chosen" in
"$screen")
	shotnow
	;;
"$area")
	shotarea
	;;
"$window")
	shotwin
	;;
"$infive")
	shot5
	;;
"$inten")
	shot10
	;;
esac
