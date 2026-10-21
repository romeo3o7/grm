fetch_latest() {
	# called as: fetch_latest $owner $project
	local owner_in=$1
	local project_in=$2
	curl -fsS "https://api.github.com/repos/$owner_in/$project_in/releases/latest"
}
