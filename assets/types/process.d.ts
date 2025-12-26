declare global {
	const process: {
		env: {
			NODE_ENV: string;
			HILOSTORY_RELEASE: string;
		};
	};
}

export {};
